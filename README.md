# Clamav Installer

Skrip Bash untuk Menginstal ClamAV versi 1.4.2 ✅

## Deskripsi

Installer Clamav adalah skrip yang dirancang untuk memudahkan proses instalasi antivirus ClamAV di sistem berbasis Linux. Skrip ini secara otomatis mengonfigurasi dan mengaktifkan layanan yang diperlukan untuk menjalankan ClamAV dengan baik.

## Prasyarat

- Sistem operasi berbasis Linux (Debian/Ubuntu).
- Akses internet untuk mengunduh paket ClamAV.
- Hak akses `sudo` untuk menginstal paket dan mengelola layanan.

## Cara Menjalankan Skrip

1. **Instalasi Default**

   Secara default, layanan `clamav-daemon.service` dan `clamav-freshclam.service` akan diaktifkan.
   ```bash
   bash install.sh
2. **Instalasi Skip Service Freshclam**
   ```bash
   bash install.sh --skip-freshclam
3. **Install Default via CURL**
   ```
   curl -sL https://raw.githubusercontent.com/awankumay/installer-clamav/main/install.sh | bash
2. **Instalasi Skip Service Freshclam via CURL**
   ```bash
   curl -sL https://raw.githubusercontent.com/awankumay/installer-clamav/main/install.sh | bash -s -- --skip-freshclam
