# Remote GUI for Ubuntu VPS (XRDP + LXQt/Xfce)
## TDLR; How to use
```bash
wget -q -O remotegui.sh https://raw.githubusercontent.com/Fadariyah/install-LXQt-Xfce-remote-desktop/refs/heads/main/remotegui.sh && sudo chmod +x remotegui.sh && ./remotegui.sh
```

สคริปต์ `remotegui.sh` ตัวนี้เอาไว้ติดตั้ง Desktop Environment แบบเบา ๆ (LXQt หรือ Xfce) บน Ubuntu Server/VPS  
และตั้งค่าให้ต่อผ่าน Remote Desktop (RDP) ได้ทันทีจากเครื่อง Desktop ของคุณ

---

## คุณสมบัติ (Features)

- ติดตั้ง Desktop Environment ให้เลือกได้สองแบบ
  - **Xfce** – เหมาะสำหรับใช้งานทั่วไปบน VPS, เสถียร และเบา
  - **LXQt** – เบามาก เหมาะกับ VPS ที่ RAM/CPU น้อย
- ติดตั้งและตั้งค่า **XRDP** (โปรโตคอล RDP มาตรฐาน)
- สร้าง session ให้ user เป้าหมาย พร้อมใช้งาน
- หากมี **UFW** และเปิดใช้งานอยู่ จะสั่ง `ufw allow 3389/tcp` ให้อัตโนมัติ
- สรุปวิธีต่อ Remote Desktop หลังติดตั้งเสร็จ

---

## รองรับสภาพแวดล้อม

- ระบบปฏิบัติการ: **Ubuntu Server** (ทดสอบกับ 20.04 / 22.04 / 24.04)
- สิทธิ์: ต้องรันด้วย **root** หรือ `sudo`
- ใช้ได้ทั้ง
  - VPS ที่ login เป็น root โดยตรง
  - หรือ VPS ที่มี user ปกติแล้วใช้ `sudo`

> ⚠️ สคริปต์นี้ออกแบบมาสำหรับ Ubuntu เท่านั้น

---

## วิธีใช้งาน

### 1. ดาวน์โหลดโค้ด / Clone Repo

```bash
git clone https://github.com/Fadariyah/install-LXQt-Xfce-remote-desktop.git
cd install-LXQt-Xfce-remote-desktop
```


หรือจะอัปโหลดไฟล์ `remotegui.sh` ตรง ๆ ก็ได้ แล้ว `cd` เข้าไปในโฟลเดอร์นั้น

---

### 2. ให้สิทธิ์รันสคริปต์

```bash
chmod +x remotegui.sh
```

---

### 3. รันสคริปต์ (แนะนำให้ใช้ sudo)

```bash
sudo ./remotegui.sh
```

หากคุณใช้ root โดยตรง:

```bash
./remotegui.sh
```

---

### 4. เลือก Desktop Environment

เมื่อรันสคริปต์ จะมีเมนูใน console ให้เลือก:

```text
เลือก Desktop Environment ที่ต้องการติดตั้ง:
  1) Xfce (แนะนำ: เบา เสถียร)
  2) LXQt (เบามาก เหมาะกับ VPS ทรัพยากรน้อย)
  q) ยกเลิก
```

- พิมพ์ `1` แล้ว Enter → ติดตั้ง Xfce
- พิมพ์ `2` แล้ว Enter → ติดตั้ง LXQt
- พิมพ์ `q` แล้ว Enter → ยกเลิก

จากนั้นสคริปต์จะ:

1. อัปเดตแพ็กเกจ (`apt-get update`, `apt-get upgrade`)
2. ติดตั้ง Xorg + XRDP
3. ติดตั้ง Desktop Environment ที่เลือก
4. ตั้งค่า `/etc/xrdp/startwm.sh` ให้เรียก desktop ที่เลือก
5. สร้างไฟล์ `~/.xsession` ให้ user ปัจจุบัน (หรือ user ที่รันด้วย sudo)
6. เปิด service XRDP และ (ถ้ามี UFW เปิดอยู่) เปิดพอร์ต `3389/tcp`

---

### 5. การเชื่อมต่อจากเครื่อง Desktop

หลังสคริปต์รันเสร็จ จะมีสรุปบนหน้าจอว่า:

- ติดตั้ง Desktop Environment อะไร
- IP ของ VPS คืออะไร (เช่น `203.0.113.10`)

#### Windows

1. เปิดโปรแกรม **Remote Desktop Connection** (ค้นหาใน Start Menu ด้วยคำว่า `mstsc`)
2. ใส่:

   - **Computer**: IP ของ VPS (เช่น `203.0.113.10`)
   - หรือ `203.0.113.10:3389` (ระบุ port ด้วยก็ได้)

3. กด **Connect**
4. ใส่ **Username** และ **Password** ตาม user บนเครื่อง Ubuntu นั้น (เช่น user ที่คุณใช้ `ssh` เข้าไป)
5. กด OK แล้วรอ Desktop ขึ้น

#### macOS

1. ติดตั้ง **Microsoft Remote Desktop** จาก Mac App Store
2. เปิดโปรแกรม แล้วกด `Add PC`
3. ใส่ IP ของ VPS ในช่อง **PC name**
4. เลือก **Add**
5. ดับเบิลคลิก PC ที่สร้าง แล้วใส่ username/password

#### Linux

สามารถใช้โปรแกรมอย่าง:

- `remmina`
- `rdesktop`
- `xfreerdp`

ตัวอย่าง (Remmina):

1. เปิด Remmina
2. สร้าง connection แบบ **RDP**
3. ใส่ IP, username, password
4. กด Connect

---

## Note / ข้อสังเกต

- ถ้าใช้ `sudo ./remotegui.sh`  
  - สคริปต์จะถือว่า user เป้าหมายคือ `$SUDO_USER`  
  - ดังนั้นเวลาต่อ RDP ให้ใช้ชื่อ user เดียวกับที่ปกติใช้ `ssh` เข้าไป (เช่น `ubuntu`, `fada`, ฯลฯ)
- ถ้ารันเป็น root โดยตรง  
  - สคริปต์จะตั้งค่า session ให้ root ที่ `/root/.xsession`  
  - **ไม่แนะนำ** ให้ login RDP เป็น root ในการใช้งานจริง (ควรสร้าง user ปกติแยกต่างหาก)

---

## ปัญหาที่พบบ่อย (Troubleshooting)

### 1. ต่อ RDP แล้วขึ้นจอดำ / เด้งออก

ลองเช็คสถานะ XRDP:

```bash
sudo systemctl status xrdp
```

ถ้าไม่ `active (running)` ให้ลอง:

```bash
sudo systemctl restart xrdp
```

แล้วลองต่อใหม่อีกครั้ง

---

### 2. ต่อไม่ติดเลย (Connection error)

- ตรวจสอบว่า RDP port 3389 เปิดใน firewall หรือไม่
- ถ้าใช้ UFW:

  ```bash
  sudo ufw status
  sudo ufw allow 3389/tcp
  ```

- ตรวจสอบว่า VPS provider ไม่มี block port 3389 เอง
- ลอง ping หรือ `ssh` IP เดียวกันได้หรือไม่

---

### 3. อยากเปลี่ยน Desktop Environment ทีหลัง

ให้ทำตามขั้นตอน:

1. ลบหรือแก้ไขเนื้อหา `/etc/xrdp/startwm.sh`
2. ติดตั้ง Desktop Environment ใหม่ (เช่น `apt-get install xfce4`)
3. แก้ `startwm.sh` ให้เรียกคำสั่งที่ต้องการ (เช่น `exec startxfce4`)
4. Restart XRDP

หรือวิธีง่าย ๆ:

- รัน `remotegui.sh` ใหม่ แล้วเลือก Desktop Environment ที่ต้องการ  
  (สคริปต์จะ backup `startwm.sh` เดิมให้ทุกครั้ง)

---

## Security Tips

- เปลี่ยนรหัสผ่าน user ที่ใช้ RDP ให้แข็งแรง (ยาว และสุ่ม)
- จำกัด IP ที่อนุญาตให้เข้าถึง port 3389 (เช่น ผ่าน UFW หรือ firewall ของผู้ให้บริการ VPS)
- พิจารณาใช้ **SSH tunnel** สำหรับ forward RDP  
  เช่น forward `localhost:3389` บนเครื่องคุณไปยัง VPS ผ่าน SSH แทนการเปิด port กับ internet โดยตรง

---

## License

เลือก license ตามที่คุณต้องการบน GitHub (เช่น MIT)
