# Setup Google Drive untuk Database Backup

## Deskripsi
Panduan ini menjelaskan cara mengkonfigurasi Google Drive untuk menyimpan backup database secara otomatis menggunakan rclone.

## Prerequisites
- Server Linux dengan akses internet
- Akun Google Drive dengan space yang cukup
- Akses root atau sudo

## Instalasi rclone

### 1. Download dan Install rclone
```bash
# Download rclone
curl https://rclone.org/install.sh | sudo bash

# Atau menggunakan package manager
# Ubuntu/Debian:
sudo apt update
sudo apt install rclone

# CentOS/RHEL:
sudo yum install rclone
# atau
sudo dnf install rclone
```

### 2. Verifikasi Instalasi
```bash
rclone version
```

## Konfigurasi Google Drive

### 1. Setup Remote Google Drive
```bash
# Jalankan konfigurasi rclone
rclone config
```

### 2. Langkah-langkah Konfigurasi
```
No remotes found - make a new one
n) New remote
s) Set configuration password
q) Quit config
n/s/q> n

name> gdrive

Type of storage to configure.
Choose a number from below, or type in your own value
...
Storage> drive

Google Application Client Id - leave blank normally.
client_id> 

Google Application Client Secret - leave blank normally.
client_secret> 

Scope that rclone should use when requesting access from drive.
Choose a number from below, or type in your own value
...
scope> 1

ID of the root folder - leave blank normally.
root_folder_id> 

Service Account Credentials JSON file path - leave blank normally.
service_account_file> 

Edit advanced config? (y/n)
y/n> n

Remote config
Use auto config?
 * Say Y if not sure
 * Say N if you are working from a headless machine or remote server
y/n> y
```

### 3. Otorisasi Google Drive
- Browser akan terbuka untuk login ke Google Drive
- Pilih akun Google yang akan digunakan
- Berikan permission untuk rclone mengakses Google Drive
- Copy authorization code yang diberikan

### 4. Verifikasi Konfigurasi
```bash
# Test koneksi
rclone lsd gdrive:

# List file di Google Drive
rclone ls gdrive:
```

## Setup Folder Google Drive (Opsional)

### 1. Buat Folder Khusus untuk Backup
1. Login ke Google Drive di browser
2. Buat folder baru dengan nama "Database_Backups"
3. Klik kanan pada folder → "Get link"
4. Copy ID folder dari URL (setelah `/folders/`)

### 2. Konfigurasi Script
Edit file `db_backup.sh` dan set:
```bash
GOOGLE_DRIVE_FOLDER_ID="your_folder_id_here"
```

## Testing Upload

### 1. Test Upload Manual
```bash
# Buat file test
echo "test backup" > test_backup.sql

# Upload ke Google Drive
rclone copy test_backup.sql gdrive:/

# Cek apakah file terupload
rclone ls gdrive: | grep test_backup.sql

# Hapus file test
rm test_backup.sql
rclone delete gdrive:/test_backup.sql
```

### 2. Test dengan Script Backup
```bash
# Jalankan script backup
sudo /usr/local/bin/db_backup.sh

# Cek log
tail -f /var/log/db_backup.log
```

## Troubleshooting

### 1. Error "rclone not found"
```bash
# Pastikan rclone terinstall
which rclone

# Jika tidak ada, install ulang
curl https://rclone.org/install.sh | sudo bash
```

### 2. Error "Remote not found"
```bash
# Cek konfigurasi yang ada
rclone listremotes

# Jika tidak ada, buat konfigurasi baru
rclone config
```

### 3. Error "Access denied"
```bash
# Re-authenticate
rclone config reconnect gdrive:

# Atau hapus dan buat ulang konfigurasi
rclone config delete gdrive
rclone config
```

### 4. Error "Quota exceeded"
- Cek space Google Drive
- Hapus backup lama di Google Drive
- Atau upgrade storage Google Drive

### 5. Error "Network timeout"
```bash
# Cek koneksi internet
ping google.com

# Cek firewall
sudo ufw status

# Test dengan timeout lebih lama
rclone copy file.sql gdrive:/ --timeout=300s
```

## Monitoring dan Maintenance

### 1. Cek Status Upload
```bash
# Cek log backup
tail -f /var/log/db_backup.log

# Cek file di Google Drive
rclone ls gdrive: | grep $(date +%d_%m_%Y)
```

### 2. Cleanup Google Drive
```bash
# Hapus backup lebih dari 30 hari
rclone lsf gdrive: | grep -E "[0-9]{2}_[0-9]{2}_[0-9]{4}" | while read file; do
    # Logic untuk hapus file lama
    echo "Checking: $file"
done
```

### 3. Monitoring Space
```bash
# Cek space Google Drive
rclone about gdrive:

# Cek ukuran folder backup
rclone size gdrive:/Database_Backups/
```

## Keamanan

### 1. Backup Konfigurasi rclone
```bash
# Backup konfigurasi
cp ~/.config/rclone/rclone.conf /backup/rclone.conf.backup

# Restore konfigurasi
cp /backup/rclone.conf.backup ~/.config/rclone/rclone.conf
```

### 2. Permission File
```bash
# Set permission yang tepat
chmod 600 ~/.config/rclone/rclone.conf
chown $USER:$USER ~/.config/rclone/rclone.conf
```

## Contoh Konfigurasi Lengkap

### File db_backup.sh
```bash
# Konfigurasi Google Drive
ENABLE_GOOGLE_DRIVE_UPLOAD=true
GOOGLE_DRIVE_FOLDER_ID="1ABC123DEF456GHI789JKL"  # ID folder Google Drive
RCLONE_CONFIG_NAME="gdrive"  # Nama konfigurasi rclone
```

### Crontab
```bash
# Backup setiap hari jam 2:00 AM
0 2 * * * /usr/local/bin/db_backup.sh
```

## Support
Jika mengalami masalah, cek:
1. Log file: `/var/log/db_backup.log`
2. Konfigurasi rclone: `rclone config show gdrive`
3. Status koneksi: `rclone lsd gdrive:`
4. Space Google Drive: `rclone about gdrive:`
