# Clamav Installer

Skrip Bash untuk Menginstal ClamAV versi 1.4.2 ✅

## Deskripsi

Installer Clamav adalah skrip yang dirancang untuk memudahkan proses instalasi antivirus ClamAV di sistem berbasis Linux. Skrip ini secara otomatis mengonfigurasi dan mengaktifkan layanan yang diperlukan untuk menjalankan ClamAV dengan baik.

## Prasyarat

- Sistem operasi berbasis Linux (Debian/Ubuntu).
- Akses internet untuk mengunduh paket ClamAV.
- Hak akses `sudo` untuk menginstal paket dan mengelola layanan.

## Cara Menjalankan Skrip

Skrip ini telah diperbarui dengan beberapa fitur baru untuk meningkatkan fungsionalitas dan kemudahan penggunaan:

### 1. Menu Bantuan
- Menampilkan informasi penggunaan skrip dan opsi yang tersedia.
- Menampilkan versi ClamAV yang terinstal jika ClamAV sudah terinstal.

### 2. Opsi Instalasi
- `--install`: Menginstal ClamAV dan mengaktifkan layanan ClamAV.
- `--skip-freshclam`: Menginstal ClamAV tetapi melewatkan pengaktifan layanan Freshclam.

### 3. Menampilkan Status Layanan
- `--status`: Menampilkan status dari layanan `clamav-daemon.service` dan `clamav-freshclam.service`, serta versi ClamAV yang terinstal.

### 4. Penanganan Parameter yang Tidak Dikenal
- Skrip akan memberikan pesan kesalahan yang jelas jika parameter yang tidak dikenal diberikan.

## Cara Menggunakan

1. **Menampilkan Pesan Bantuan**:
   Untuk menampilkan pesan bantuan dan opsi yang tersedia, jalankan:
   ```bash
   curl -sL https://raw.githubusercontent.com/awankumay/installer-clamav/main/install.sh | bash -s -- --help

2. **Install Clamav & Enable Service**:
   Untuk melakukan install, jalankan:
   ```bash
   curl -sL https://raw.githubusercontent.com/awankumay/installer-clamav/main/install.sh | bash -s -- --install

3. **Install Clamav & Skip Service Freshclam**:
   Untuk melakukan install dengan skip Service Freshclam, jalankan:
   ```bash
   curl -sL https://raw.githubusercontent.com/awankumay/installer-clamav/main/install.sh | bash -s -- --skip-freshclam

4. **Check Status Service**:
   Untuk melakukan check status service, jalankan:
   ```bash
   curl -sL https://raw.githubusercontent.com/awankumay/installer-clamav/main/install.sh | bash -s -- --status