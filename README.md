# 🍯 #JAMU WIFI ID (Versi Final & Stabil)

Skrip otomatisasi untuk menjaga kesehatan IP perangkat Linux Debian/Ubuntu yang menjalankan **EarnApp**. Skrip ini akan secara otomatis menyaring IP publik, mencocokkannya dengan server backend EarnApp, melakukan pengacakan MAC Address (`macchanger`) jika IP terblokir (**RED**), dan mengunci IP jika berstatus aman (**GREEN**).

---

## 📋 Alur Logika Sistem
1. **Pengecekan Awal:** Device menyala (*booting*) → Menunggu internet aktif → Mendapatkan IP Publik baru.
2. **Penyaringan Lokal:** IP baru dicek ke database `/etc/ip_blacklist.txt`. Jika sudah ada di daftar hitam, device langsung memicu penggantian MAC dan *reboot*.
3. **Masa Sinkronisasi:** Jika IP belum di-blacklist, internet dibiarkan **tetap menyala normal selama 1 menit (60 detik)** agar aplikasi EarnApp di latar belakang (*background*) bisa berjalan online dan mengirim data ke server pusat.
4. **Validasi Akhir:** Server EarnApp ditembak secara langsung. 
   * Jika status **RED / MERAH ❌**, IP dimasukkan ke daftar blacklist lokal (lengkap dengan tanggal & jam), MAC Address diacak, lalu device otomatis *reboot* mencari IP baru.
   * Jika status **GREEN / HIJAU  (Earning)**, IP dimasukkan ke whitelist lokal dan koneksi **dikunci secara permanen** (tidak akan memicu *reboot* berulang).

---

## 🛠️ Cara Install di Device Baru (Hanya 1 Perintah)

Buka terminal pada device baru Anda, lalu jalankan **1 baris perintah** di bawah ini (Pastikan untuk mengubah `USERNAME_ANDA` sesuai dengan nama akun GitHub Anda):

```bash
curl -sSL https://githubusercontent.com | bash
```

---

## 📊 Perintah Pemeliharaan & Pemantauan

### 1. Melihat Proses Hitung Mundur dan Status Secara Live
Untuk memantau apakah device Anda sedang dalam posisi jeda sinkronisasi, mendeteksi IP, atau bersiap melakukan *reboot*, gunakan perintah:
```bash
sudo journalctl -u ip-filter.service -f -n 50
```

### 2. Melihat Laporan Daftar IP Ampas yang Sudah Diblokir
Untuk melihat riwayat IP mana saja yang terjaring blokir beserta tanggal dan jam kejadiannya:
```bash
cat /etc/ip_blacklist.txt
```

### 3. Mengosongkan Total Database IP (Reset Ulang dari Nol)
Jika Anda ingin membersihkan ulang daftar *whitelist* dan *blacklist* lokal agar sistem mencari data baru:
```bash
sudo truncate -s 0 /etc/ip_whitelist.txt && sudo truncate -s 0 /etc/ip_blacklist.txt
```

### 4. Mematikan Total Sistem #JAMU WIFI ID
Jika Anda ingin melakukan perbaikan manual atau menghentikan siklus pencarian IP untuk sementara waktu:
```bash
sudo systemctl stop ip-filter.service && sudo systemctl disable ip-filter.service
```

---
**Catatan Penting:** Secara bawaan skrip ini menggunakan interface jaringan `wlan0`. Jika device baru Anda menggunakan kabel LAN atau nama interface lain (seperti `eth0`, `enp3s0`), pastikan untuk mengedit baris `INTERFACE="wlan0"` di dalam file `install.sh` di GitHub Anda sebelum melakukan instalasi.
