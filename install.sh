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
SKIP_FRESHCLAM=false
INSTALL=false
SHOW_STATUS=false

# Fungsi untuk menampilkan pesan error dan keluar
error() {
  echo "Error: $1" >&2
  exit 1
}

# Fungsi untuk menampilkan pesan bantuan
show_help() {
  echo "Usage: $0 [OPTIONS]"
  if command -v clamscan &> /dev/null; then
    CLAMAV_VERSION=$(clamscan --version | head -n 1)
    echo "ClamAV Status: $CLAMAV_VERSION"
  else
    echo "ClamAV Status: Not installed"
  fi
  echo "Options:"
  echo "  --install         Install ClamAV & Enable Service"
  echo "  --skip-freshclam  Install ClamAV & Skip Service"
  echo "  --help            Display this help message"
  echo "  --status          Show Status of clamav-daemon.service & clamav-freshclam.service"
}

# Fungsi untuk menampilkan status layanan
show_status() {
  if command -v clamscan &> /dev/null; then
    CLAMAV_VERSION=$(clamscan --version | head -n 1)
    echo "ClamAV Status: $CLAMAV_VERSION"
  else
    echo "ClamAV Status: Not installed"
  fi
  echo "clamav-daemon.service: $(systemctl is-active clamav-daemon.service)"
  echo "clamav-freshclam.service: $(systemctl is-active clamav-freshclam.service)"
}

# Pastikan skrip dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
  error "Skrip ini harus dijalankan sebagai root (sudo)."
fi

# Parsing parameter
for arg in "$@"; do
  case $arg in
    --install)
      INSTALL=true
      ;;
    --skip-freshclam)
      INSTALL=true
      SKIP_FRESHCLAM=true
      ;;
    --help)
      show_help
      exit 0
      ;;
    --status)
      SHOW_STATUS=true
      ;;
    *)
      echo "Parameter tidak dikenal: $arg"
      show_help
      exit 1
      ;;
  esac
done

# Jika tidak ada argumen atau hanya --help, tampilkan pesan bantuan
if [ "$#" -eq 0 ] || [ "$SHOW_HELP" = true ]; then
  show_help
  exit 0
fi

# Jika --status ditentukan, tampilkan status layanan dan keluar
if [ "$SHOW_STATUS" = true ]; then
  show_status
  exit 0
fi

# Jika --install tidak ditentukan, keluar dengan pesan bantuan
if [ "$INSTALL" = false ]; then
  echo "Pilihan --install harus ditentukan untuk melanjutkan instalasi."
  show_help
  exit 1
fi

# Cek apakah ClamAV sudah terinstal
if dpkg -l | grep -q '^ii.*clamav'; then
  INSTALLED_VERSION=$(dpkg -l | grep '^ii.*clamav' | awk '{print $3}')
  echo "ClamAV sudah terinstal dengan versi: $INSTALLED_VERSION"
  systemctl stop clamav-daemon.service clamav-freshclam.service
  # Buat ulang direktori jika diperlukan
  mkdir -p /var/run/clamav
  chown clamav:clamav /var/run/clamav
  chmod 750 /var/run/clamav
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

# Fungsi untuk mengaktifkan dan memulai layanan dengan konfirmasi
enable_and_start_service() {
  local service_name=$1
  local service_desc=$2

  echo "Mengaktifkan dan memulai $service_desc..."
  systemctl enable "$service_name" >/dev/null 2>&1 || {
    echo "Gagal mengaktifkan $service_desc. Periksa konfigurasi layanan."
    return 1
  }
  systemctl start "$service_name" >/dev/null 2>&1 || {
    echo "Gagal memulai $service_desc. Periksa log sistem untuk detailnya."
    return 1
  }
  if systemctl is-active --quiet "$service_name"; then
    echo "$service_desc berhasil diaktifkan dan berjalan."
  else
    echo "$service_desc tidak berjalan. Periksa log sistem."
  fi
}

# Aktivasi Clamav-Daemon
enable_and_start_service "clamav-daemon.service" "Clamav-Daemon"

# Jika --skip-freshclam tidak diberikan, aktifkan freshclam service
if [ "$SKIP_FRESHCLAM" = false ]; then
  enable_and_start_service "clamav-freshclam.service" "Clamav-Freshclam"
else
  echo "Service Clamav-Freshclam di-skip sesuai parameter --skip-freshclam."
fi

echo "Instalasi ClamAV selesai."
