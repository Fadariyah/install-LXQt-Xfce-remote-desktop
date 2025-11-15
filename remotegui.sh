#!/usr/bin/env bash
#
# remotegui.sh
# ติดตั้ง Desktop Environment (LXQt / Xfce) + XRDP บน Ubuntu Server/VPS
# หลังรันจบสามารถใช้ Remote Desktop (RDP) ต่อจากเครื่อง Desktop ได้ทันที

set -e

#-----------------------------
# สีสำหรับข้อความ
#-----------------------------
CLR_GREEN="\e[32m"
CLR_YELLOW="\e[33m"
CLR_RED="\e[31m"
CLR_CYAN="\e[36m"
CLR_RESET="\e[0m"
CLR_BOLD="\e[1m"

info()  { echo -e "${CLR_CYAN}[INFO]${CLR_RESET} $1"; }
ok()    { echo -e "${CLR_GREEN}[OK]${CLR_RESET} $1"; }
warn()  { echo -e "${CLR_YELLOW}[WARN]${CLR_RESET} $1"; }
error() { echo -e "${CLR_RED}[ERROR]${CLR_RESET} $1"; }

#-----------------------------
# ตรวจสอบสิทธิ์ root
#-----------------------------
require_root() {
    if [ "$EUID" -ne 0 ]; then
        error "กรุณารันสคริปต์นี้ด้วยสิทธิ์ root (เช่น sudo ./remotegui.sh)"
        exit 1
    fi
}

#-----------------------------
# ตรวจสอบว่าเป็น Ubuntu
#-----------------------------
check_ubuntu() {
    if [ ! -f /etc/os-release ]; then
        error "ไม่พบไฟล์ /etc/os-release สคริปต์นี้รองรับ Ubuntu เท่านั้น"
        exit 1
    fi

    . /etc/os-release

    if [[ "$ID" != "ubuntu" ]]; then
        error "สคริปต์นี้รองรับเฉพาะ Ubuntu (ตรวจพบ: $NAME)"
        exit 1
    fi

    info "ตรวจพบระบบ: $PRETTY_NAME"
}

#-----------------------------
# เลือก Desktop Environment
#-----------------------------
select_desktop_env() {
    echo -e "${CLR_BOLD}เลือก Desktop Environment ที่ต้องการติดตั้ง:${CLR_RESET}"
    echo "  1) Xfce (แนะนำ: เบา เสถียร)"
    echo "  2) LXQt (เบามาก เหมาะกับ VPS ทรัพยากรน้อย)"
    echo "  q) ยกเลิก"

    while true; do
        read -rp "พิมพ์หมายเลข (1/2) หรือ q: " choice
        case "$choice" in
            1)
                DESKTOP_NAME="Xfce"
                SESSION_CMD="startxfce4"
                DE_PACKAGES="xfce4 xfce4-goodies"
                ok "เลือก Xfce"
                break
                ;;
            2)
                DESKTOP_NAME="LXQt"
                SESSION_CMD="lxqt-session"
                DE_PACKAGES="lxqt-core openbox"
                ok "เลือก LXQt"
                break
                ;;
            q|Q)
                warn "ยกเลิกการทำงาน"
                exit 0
                ;;
            *)
                warn "ตัวเลือกไม่ถูกต้อง กรุณาลองใหม่"
                ;;
        esac
    done
}

#-----------------------------
# หาชื่อ user เป้าหมาย (สำหรับ login ผ่าน RDP)
#-----------------------------
detect_target_user() {
    # ถ้าใช้ sudo จะได้ user จริงจาก SUDO_USER
    TARGET_USER="${SUDO_USER:-$USER}"

    # กันกรณี script ถูกรันเป็น root โดยตรง (ไม่มี user ปกติ)
    if [ "$TARGET_USER" = "root" ]; then
        warn "กำลังรันในฐานะ root จะตั้งค่า session ให้ root"
        USER_HOME="/root"
    else
        USER_HOME="/home/$TARGET_USER"
    fi

    if [ ! -d "$USER_HOME" ]; then
        warn "ไม่พบ home directory ของ $TARGET_USER ที่ $USER_HOME"
        warn "ยังสามารถใช้ RDP login ด้วย user อื่นได้ แต่ต้องตั้งค่า session เองภายหลัง"
    fi

    info "User สำหรับทดสอบ login RDP: ${TARGET_USER}"
}

#-----------------------------
# อัปเดตระบบ และติดตั้งแพ็กเกจพื้นฐาน + XRDP
#-----------------------------
install_common_packages() {
    info "อัปเดตรายการแพ็กเกจ..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y

    info "อัปเกรดแพ็กเกจ (อาจใช้เวลาสักพัก)..."
    apt-get upgrade -y

    info "ติดตั้งแพ็กเกจพื้นฐานสำหรับ GUI + XRDP..."
    apt-get install -y xorg dbus-x11 x11-xserver-utils
    apt-get install -y xrdp
}

#-----------------------------
# ติดตั้ง Desktop Environment ที่เลือก
#-----------------------------
install_desktop_env() {
    info "ติดตั้ง Desktop Environment: ${DESKTOP_NAME}"
    apt-get install -y $DE_PACKAGES

    ok "ติดตั้ง ${DESKTOP_NAME} เสร็จแล้ว"
}

#-----------------------------
# ตั้งค่า XRDP ให้ใช้ Desktop ที่เลือก
#-----------------------------
configure_xrdp() {
    info "ตั้งค่า XRDP..."

    # สำรองไฟล์ startwm.sh เดิม
    if [ -f /etc/xrdp/startwm.sh ]; then
        BACKUP_FILE="/etc/xrdp/startwm.sh.bak.$(date +%F-%H%M%S)"
        cp /etc/xrdp/startwm.sh "$BACKUP_FILE"
        info "สำรอง /etc/xrdp/startwm.sh เป็น $BACKUP_FILE"
    fi

    cat >/etc/xrdp/startwm.sh <<EOF
#!/bin/sh
# startwm.sh ถูกตั้งค่าโดย remotegui.sh

if [ -r /etc/default/locale ]; then
    . /etc/default/locale
    export LANG LANGUAGE
fi

# เรียก Desktop Environment ที่เลือก
exec ${SESSION_CMD}
EOF

    chmod +x /etc/xrdp/startwm.sh

    # เพิ่ม user xrdp เข้า group ssl-cert เพื่อใช้ certificate
    if getent group ssl-cert >/dev/null 2>&1; then
        adduser xrdp ssl-cert >/dev/null 2>&1 || true
    fi

    # สร้างไฟล์ .xsession ให้ user เป้าหมาย (ถ้ามี home)
    if [ -d "$USER_HOME" ]; then
        info "สร้างไฟล์ session สำหรับ user: $TARGET_USER"

        cat >"${USER_HOME}/.xsession" <<EOF
#!/bin/sh
exec ${SESSION_CMD}
EOF

        chown "${TARGET_USER}:${TARGET_USER}" "${USER_HOME}/.xsession" 2>/dev/null || true
        chmod +x "${USER_HOME}/.xsession" 2>/dev/null || true
    fi

    # เปิด service
    systemctl enable xrdp >/dev/null 2>&1 || true
    systemctl restart xrdp

    ok "ตั้งค่า XRDP เสร็จแล้ว"
}

#-----------------------------
# ตั้งค่า Firewall (UFW) ให้เปิดพอร์ต 3389 ถ้ามี
#-----------------------------
configure_firewall() {
    if command -v ufw >/dev/null 2>&1; then
        UFW_STATUS=$(ufw status | head -n1 | awk '{print $2}')
        if [ "$UFW_STATUS" = "active" ]; then
            info "ตรวจพบ UFW ทำการเปิดพอร์ต 3389/tcp สำหรับ RDP..."
            ufw allow 3389/tcp || warn "เปิดพอร์ต 3389 บน UFW ไม่สำเร็จ กรุณาตรวจสอบเอง"
        else
            info "UFW ไม่ได้เปิดใช้งาน (status: $UFW_STATUS) ข้ามการตั้งค่า firewall"
        fi
    else
        info "ไม่พบ UFW ข้ามการตั้งค่า firewall (หากมี firewall อื่น กรุณาเปิดพอร์ต 3389 เอง)"
    fi
}

#-----------------------------
# แสดงสรุป และคำแนะนำการเชื่อมต่อ
#-----------------------------
show_summary() {
    echo
    echo -e "${CLR_BOLD}${CLR_GREEN}=== การติดตั้งเสร็จสมบูรณ์ ===${CLR_RESET}"
    echo
    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

    if [ -n "$SERVER_IP" ]; then
        echo -e "IP ของ VPS คุณ: ${CLR_BOLD}$SERVER_IP${CLR_RESET}"
    else
        echo -e "ไม่สามารถตรวจจับ IP ได้อัตโนมัติ ให้ใช้คำสั่ง ${CLR_BOLD}ip addr show${CLR_RESET} เพื่อตรวจสอบ"
    fi

    cat <<EOF

Desktop Environment ที่ติดตั้ง: ${DESKTOP_NAME}
Remote Desktop Protocol  : XRDP (Port 3389)

วิธีเชื่อมต่อจากเครื่อง Desktop:

  1) เปิดโปรแกรม Remote Desktop (RDP client)
     - Windows: "Remote Desktop Connection"
     - macOS: "Microsoft Remote Desktop" (ดาวน์โหลดจาก App Store)
     - Linux: remmina หรือ rdesktop

  2) ใส่ข้อมูล:
     - Computer / Host:  IP ของ VPS (เช่น ${SERVER_IP:-<server-ip>})
     - Port           :  3389
     - Username       :  ${TARGET_USER}  (หรือ user อื่นที่มีบนระบบ)
     - Password       :  รหัสผ่านของ user นั้น

  3) กด Connect แล้วรอให้ Desktop ขึ้น

คำแนะนำด้านความปลอดภัย (ควรทำเพิ่มเอง):
  - เปลี่ยนรหัสผ่านให้แข็งแรง
  - จำกัด IP ที่อนุญาตให้เข้า port 3389
  - หรือใช้ SSH tunnel เพื่อ forward RDP แทนการเปิดพอร์ตกับ internet ตรง ๆ

EOF
}

#-----------------------------
# main
#-----------------------------
main() {
    clear
    echo -e "${CLR_BOLD}Remote GUI Installer for Ubuntu VPS${CLR_RESET}"
    echo    "------------------------------------"
    echo

    require_root
    check_ubuntu
    select_desktop_env
    detect_target_user
    install_common_packages
    install_desktop_env
    configure_xrdp
    configure_firewall
    show_summary
}

main "$@"
