#!/bin/bash

# Variabel
VERSION="1.4.2"
PACKAGE_URL="https://www.clamav.net/downloads/production/clamav-${VERSION}.linux.x86_64.deb"
PACKAGE_FILE="clamav-${VERSION}.linux.x86_64.deb"
CLAMD_CONF_URL="https://raw.githubusercontent.com/awankumay/installer-clamav/main/clamd.conf"
FRESHCLAM_CONF_URL="https://raw.githubusercontent.com/awankumay/installer-clamav/main/freshclam.conf"
CLAMAV_DAEMON_SERVICE_URL="https://raw.githubusercontent.com/awankumay/installer-clamav/main/clamav-daemon.service"
CLAMAV_FRESHCLAM_SERVICE_URL="https://raw.githubusercontent.com/awankumay/installer-clamav/main/clamav-freshclam.service"
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

# Unduh file konfigurasi dari GitHub
echo "Mengunduh file konfigurasi dari GitHub..."
wget -q "$CLAMD_CONF_URL" -O /usr/local/etc/clamd.conf || error "Gagal mengunduh clamd.conf dari GitHub."
wget -q "$FRESHCLAM_CONF_URL" -O /usr/local/etc/freshclam.conf || error "Gagal mengunduh freshclam.conf dari GitHub."

# Unduh file service dari GitHub
echo "Mengunduh file service dari GitHub..."
wget -q "$CLAMAV_DAEMON_SERVICE_URL" -O /etc/systemd/system/clamav-daemon.service || error "Gagal mengunduh clamav-daemon.service dari GitHub."
wget -q "$CLAMAV_FRESHCLAM_SERVICE_URL" -O /etc/systemd/system/clamav-freshclam.service || error "Gagal mengunduh clamav-freshclam.service dari GitHub."

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Perbarui database virus
echo "Memperbarui database virus..."
/usr/local/bin/freshclam || error "Gagal memperbarui database virus."

# Aktifkan dan mulai service dengan konfirmasi
confirm_service() {
  local service_name=$1
  local service_desc=$2
  read -p "Aktifkan dan jalankan service $service_desc? (y/t): " response
  case "$response" in
    [Yy]*)
      echo "Mengaktifkan dan memulai $service_desc..."
      systemctl enable "$service_name"
      systemctl start "$service_name"
      systemctl status "$service_name"
      ;;
    [Tt]*)
      echo "Service $service_desc tidak diaktifkan."
      ;;
    *)
      echo "Input tidak valid. Abaikan aktivasi $service_desc."
      ;;
  esac
}

# Konfirmasi untuk setiap service
confirm_service "clamav-daemon.service" "Clamav-Daemon"
confirm_service "clamav-freshclam.service" "Clamav-Freshclam"

echo "Instalasi ClamAV selesai."
