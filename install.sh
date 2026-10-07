#!/bin/bash

# === PROGRAM ONE-LINE INSTALLER #JAMU WIFI ID ===
echo "=================================================="
echo "      MEMULAI INSTALASI #JAMU WIFI ID             "
echo "=================================================="

# 1. Update dan install paket pendukung
echo "[1/5] Menginstal paket pendukung (curl, jq, macchanger)..."
sudo apt update && sudo apt install curl jq macchanger -y

# 2. Buat database IP lokal jika belum ada
echo "[2/5] Membuat database IP Whitelist & Blacklist lokal..."
sudo touch /etc/ip_whitelist.txt
sudo touch /etc/ip_blacklist.txt

# 3. Download Script Utama langsung ke /usr/local/bin/
echo "[3/5] Membuat script utama ip_check.sh..."
sudo cat << 'EOF' > /usr/local/bin/ip_check.sh
#!/bin/bash

# === KONFIGURASI ===
INTERFACE="wlan0" 
WHITELIST_FILE="/etc/ip_whitelist.txt"
BLACKLIST_FILE="/etc/ip_blacklist.txt"
# ===================

echo "=== Memulai Pengecekan IP & Status Real-Time Dashboard EarnApp ==="

action_trigger_reboot() {
    echo "=== ATURAN TIMER: Menunggu 1 menit (60 detik) sebelum device reboot... ==="
    sleep 60
    echo "Memulai ulang device sekarang..."
    sudo reboot
    exit 0
}

while true; do
    CURRENT_IP=$(curl -s --max-time 5 https://icanhazip.com | tr -d '[:space:]')
    if [ ! -z "$CURRENT_IP" ] && [[ "$CURRENT_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "IP Saat Ini Berhasil Didapatkan: $CURRENT_IP"
        break
    fi
    echo "Menunggu koneksi internet aktif untuk pengecekan awal..."
    sleep 3
done

if grep -q "$CURRENT_IP" "$BLACKLIST_FILE" 2>/dev/null; then
    echo "[LOKAL BLACKLIST] IP ini ada di Blacklist lokal! Mengacak MAC & memicu siklus reboot..."
    
    sudo systemctl stop NetworkManager 2>/dev/null
    sudo systemctl stop wpa_supplicant 2>/dev/null
    sudo ip link set dev $INTERFACE down
    sleep 1
    sudo macchanger -r $INTERFACE
    sleep 1
    sudo ip link set dev $INTERFACE up
    sudo systemctl start NetworkManager 2>/dev/null
    sudo systemctl start wpa_supplicant 2>/dev/null
    
    action_trigger_reboot
fi

if grep -Fxq "$CURRENT_IP" "$WHITELIST_FILE" 2>/dev/null; then
    echo "[LOKAL WHITELIST] IP terdaftar di Whitelist. MENAHAN IP INI. Device siap digunakan."
    while true; do
        sleep 3600
    done
fi

echo "=== LOGIKA SINKRONISASI: IP baru terdeteksi. EarnApp berjalan online secara background. ==="
echo "=== Menunggu 1 menit (60 detik) membiarkan EarnApp mengirim data agar status Dashboard ter-update... ==="

for ((i=60; i>0; i-=10)); do
    echo "Sisa waktu tunggu sinkronisasi dashboard: $i detik..."
    sleep 10
done

echo "Waktu tunggu selesai. Mengecek hasil akhir status IP langsung ke server EarnApp..."
CHECK_ALLOWED=$(curl -s --max-time 10 "https://earnapp.com")

if echo "$CHECK_ALLOWED" | grep -q '"allowed":false' || echo "$CHECK_ALLOWED" | grep -iq "blocked"; then
    echo "[STATUS EARNAPP] RED / MERAH ❌ (IP Resmi Diblokir oleh Dashboard!)"
    
    WAKTU_BLOKIR=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$WAKTU_BLOKIR] - $CURRENT_IP - BLOCKED" >> "$BLACKLIST_FILE"
    
    sudo systemctl stop NetworkManager 2>/dev/null
    sudo systemctl stop wpa_supplicant 2>/dev/null
    sudo ip link set dev $INTERFACE down
    sleep 1
    sudo macchanger -r $INTERFACE
    sleep 1
    sudo ip link set dev $INTERFACE up
    sudo systemctl start NetworkManager 2>/dev/null
    sudo systemctl start wpa_supplicant 2>/dev/null
    
    action_trigger_reboot
else
    echo "[STATUS EARNAPP] GREEN / HIJAU  (IP Bersih & Earning!)"
    if ! grep -Fxq "$CURRENT_IP" "$WHITELIST_FILE" 2>/dev/null; then
        echo "$CURRENT_IP" >> "$WHITELIST_FILE"
    fi
    
    echo "[SUKSES] IP aman dan dikunci secara permanen."
    while true; do
        sleep 3600
    done
fi
EOF

# Berikan izin eksekusi script utama
sudo chmod +x /usr/local/bin/ip_check.sh

# 4. Buat Systemd Service Configuration
echo "[4/5] Membuat konfigurasi Systemd Service anti-timeout..."
sudo cat << 'EOF' > /etc/systemd/system/ip-filter.service
[Unit]
Description=IP Filtering Whitelist Blacklist dan MacChanger dengan Delay Timer #JAMU WIFI ID
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/bin/bash /usr/local/bin/ip_check.sh
User=root
Restart=no
TimeoutStartSec=infinity
TimeoutSec=infinity

[Install]
WantedBy=multi-user.target
EOF

# 5. Reload dan Aktifkan Otomatisasi
echo "[5/5] Mengaktifkan service otomatis di sistem..."
sudo systemctl daemon-reload
sudo systemctl enable ip-filter.service
sudo systemctl restart ip-filter.service

echo "=================================================="
echo "  PROSES INSTALASI SELESAI & SISTEM SUDAH AKTIF!  "
echo "=================================================="
