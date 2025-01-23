#!/bin/bash

# Variabel
VERSION="1.4.2"
PACKAGE_URL="https://www.clamav.net/downloads/production/clamav-${VERSION}.linux.x86_64.deb"
PACKAGE_FILE="clamav-${VERSION}.linux.x86_64.deb"
CLAMD_CONF="./clamd.conf"
FRESHCLAM_CONF="./freshclam.conf"
CLAMAV_DAEMON_SERVICE="./clamav-daemon.service"
CLAMAV_FRESHCLAM_SERVICE="./clamav-freshclam.service"
CLAMAV_USER="clamav"
CLAMAV_GROUP="clamav"

# Fungsi untuk menampilkan pesan error dan keluar
error() {
  echo "Error: $1" >&2
  exit 1
}

# Pastikan skrip dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
  error "Skrip ini harus dijalankan sebagai root (sudo)."
fi

# Cek apakah ClamAV sudah terinstal
if dpkg -l | grep -q '^ii.*clamav'; then
  INSTALLED_VERSION=$(dpkg -l | grep '^ii.*clamav' | awk '{print $3}')
  echo "ClamAV sudah terinstal dengan versi: $INSTALLED_VERSION"
  systemctl stop clamav-daemon.service clamav-freshclam.service
  CLAMAV_INSTALLED=true
else
  echo "ClamAV belum terinstal."
  CLAMAV_INSTALLED=false
fi

# Unduh dan instal ClamAV
echo "Mengunduh paket ClamAV..."
wget -q "$PACKAGE_URL" -O "$PACKAGE_FILE" || error "Gagal mengunduh paket."

echo "Menginstal paket ClamAV..."
dpkg -i "$PACKAGE_FILE" || error "Gagal menginstal paket. Perbaiki dependensi dengan 'apt-get install -f'."
apt-get install -f -y

rm "$PACKAGE_FILE"

# Buat user dan group ClamAV jika belum ada
if ! getent group "$CLAMAV_GROUP" >/dev/null; then
  echo "Membuat group $CLAMAV_GROUP..."
  groupadd "$CLAMAV_GROUP"
fi
if ! getent passwd "$CLAMAV_USER" >/dev/null; then
  echo "Membuat user $CLAMAV_USER..."
  useradd -g "$CLAMAV_GROUP" -s /bin/false -c "Clam AntiVirus" "$CLAMAV_USER"
fi

# Buat direktori yang dibutuhkan
echo "Membuat direktori..."
for DIR in /var/run/clamav /var/log/clamav /usr/local/share/clamav /var/lib/clamav; do
  mkdir -p "$DIR"
  chown "$CLAMAV_USER:$CLAMAV_GROUP" "$DIR"
done

# Salin file konfigurasi
echo "Menyalin file konfigurasi..."
cp "$CLAMD_CONF" /usr/local/etc/clamd.conf
cp "$FRESHCLAM_CONF" /usr/local/etc/freshclam.conf
cp "$CLAMAV_DAEMON_SERVICE" /etc/systemd/system/clamav-daemon.service
cp "$CLAMAV_FRESHCLAM_SERVICE" /etc/systemd/system/clamav-freshclam.service

# Perbarui database virus
echo "Memperbarui database virus..."
/usr/local/bin/freshclam || error "Gagal memperbarui database virus."

# Aktifkan dan mulai service
echo "Mengaktifkan dan memulai service..."
if [[ "$CLAMAV_INSTALLED" == true ]]; then
  echo "Reloading systemd daemon karena ClamAV sudah terinstal sebelumnya..."
  systemctl daemon-reload
fi

systemctl enable clamav-daemon.service clamav-freshclam.service
systemctl start clamav-daemon.service clamav-freshclam.service
echo "Silahkan melakukan check status service (systemctl status clamav-daemon.service clamav-freshclam.service)"
# systemctl status clamav-daemon.service clamav-freshclam.service

echo "Instalasi ClamAV selesai."
