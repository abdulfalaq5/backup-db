# Database Backup Script - Panduan Instalasi dan Konfigurasi

## Deskripsi
Script ini digunakan untuk melakukan backup otomatis database MySQL dan PostgreSQL dengan fitur:
- **Auto-detect semua database** MySQL dan PostgreSQL
- **Format nama file**: `nama_database_dd_mm_yyyy.sql`
- **Upload otomatis ke Google Drive** menggunakan rclone
- **Logging lengkap** proses backup
- **Cleanup backup lama** (lebih dari 7 hari)
- **Tidak perlu kompresi** - file langsung dalam format SQL

## Instalasi

### 1. Download dan Setup Script
```bash
# Download script ke server
sudo wget -O /usr/local/bin/db_backup.sh https://your-server.com/db_backup.sh

# Berikan permission execute
sudo chmod +x /usr/local/bin/db_backup.sh

# Buat direktori backup
sudo mkdir -p /var/backups/databases
sudo chown root:root /var/backups/databases
```

### 2. Konfigurasi Script
Edit file script untuk menyesuaikan dengan environment Anda:

```bash
sudo nano /usr/local/bin/db_backup.sh
```

**Konfigurasi yang perlu disesuaikan:**

```bash
# Konfigurasi MySQL
MYSQL_HOST="162.11.0.232"          # Ganti dengan host MySQL Anda
MYSQL_PORT="3306"                   # Port MySQL
MYSQL_USER="root"                   # Username MySQL
MYSQL_PASSWORD="your_mysql_password" # Password MySQL
# Database akan dideteksi otomatis

# Konfigurasi PostgreSQL
PG_HOST="localhost"                 # Host PostgreSQL
PG_USER="sharedpg"                  # Username PostgreSQL
PG_PASSWORD="pgpass"                # Password PostgreSQL
# Database akan dideteksi otomatis

# Konfigurasi Google Drive (opsional)
ENABLE_GOOGLE_DRIVE_UPLOAD=true
GOOGLE_DRIVE_FOLDER_ID=""  # ID folder Google Drive tujuan
RCLONE_CONFIG_NAME="gdrive"  # Nama konfigurasi rclone
```

### 3. Setup Google Drive (Opsional)

**Install rclone:**
```bash
curl https://rclone.org/install.sh | sudo bash
```

**Konfigurasi Google Drive:**
```bash
rclone config
# Ikuti panduan lengkap di file GOOGLE_DRIVE_SETUP.md
```

**Test koneksi:**
```bash
rclone lsd gdrive:
```

### 4. Setup Cronjob

**Untuk root user:**
```bash
sudo crontab -e
```

**Untuk user biasa:**
```bash
crontab -e
```

**Tambahkan salah satu konfigurasi berikut:**

```bash
# Backup setiap hari jam 2:00 AM
0 2 * * * /usr/local/bin/db_backup.sh

# Backup setiap 6 jam
0 */6 * * * /usr/local/bin/db_backup.sh

# Backup setiap hari kerja jam 1:00 AM
0 1 * * 1-5 /usr/local/bin/db_backup.sh
```

## Struktur Backup

Setiap backup akan membuat folder dengan format tanggal:
```
/var/backups/databases/
├── 01_12_2024/
│   ├── db_asset_it_01_12_2024.sql
│   ├── core-api-cum_01_12_2024.sql
│   └── database2_01_12_2024.sql
├── 02_12_2024/
│   ├── db_asset_it_02_12_2024.sql
│   └── core-api-cum_02_12_2024.sql
└── ...
```

**Format nama file**: `nama_database_dd_mm_yyyy.sql`

## Monitoring dan Log

### Log File
Script akan membuat log di: `/var/log/db_backup.log`

### Contoh Log Output
```
[2024-12-01 02:00:01] === MULAI PROSES BACKUP DATABASE ===
[2024-12-01 02:00:01] Direktori backup dibuat: /var/backups/databases/01_12_2024
[2024-12-01 02:00:01] Mendeteksi database MySQL...
[2024-12-01 02:00:02] Database MySQL ditemukan: db_asset_it database2 database3
[2024-12-01 02:00:02] Mendeteksi database PostgreSQL...
[2024-12-01 02:00:03] Database PostgreSQL ditemukan: core-api-cum database2 database3
[2024-12-01 02:00:03] Memulai backup MySQL...
[2024-12-01 02:00:03] Backup database MySQL: db_asset_it
[2024-12-01 02:00:05] ✓ Backup MySQL berhasil: db_asset_it
[2024-12-01 02:00:05] ✓ File backup: /var/backups/databases/01_12_2024/db_asset_it_01_12_2024.sql
[2024-12-01 02:00:05] Memulai backup PostgreSQL...
[2024-12-01 02:00:05] Backup database PostgreSQL: core-api-cum
[2024-12-01 02:00:08] ✓ Backup PostgreSQL berhasil: core-api-cum
[2024-12-01 02:00:08] ✓ File backup: /var/backups/databases/01_12_2024/core-api-cum_01_12_2024.sql
[2024-12-01 02:00:08] === INFORMASI BACKUP ===
[2024-12-01 02:00:08] Tanggal backup: Sun Dec  1 02:00:08 UTC 2024
[2024-12-01 02:00:08] Direktori backup: /var/backups/databases/01_12_2024
[2024-12-01 02:00:08] Ukuran backup: 15M
[2024-12-01 02:00:08] Jumlah file: 2
[2024-12-01 02:00:08] ========================
[2024-12-01 02:00:08] Memulai upload ke Google Drive...
[2024-12-01 02:00:08] Uploading: db_asset_it_01_12_2024.sql
[2024-12-01 02:00:12] ✓ Upload berhasil: db_asset_it_01_12_2024.sql
[2024-12-01 02:00:12] Uploading: core-api-cum_01_12_2024.sql
[2024-12-01 02:00:16] ✓ Upload berhasil: core-api-cum_01_12_2024.sql
[2024-12-01 02:00:16] Upload ke Google Drive selesai
[2024-12-01 02:00:16] Membersihkan backup lama (lebih dari 7 hari)...
[2024-12-01 02:00:16] Cleanup backup lama selesai
[2024-12-01 02:00:16] === PROSES BACKUP SELESAI ===
```

## Testing Script

### Test Manual
```bash
# Jalankan script secara manual untuk testing
sudo /usr/local/bin/db_backup.sh

# Cek log
tail -f /var/log/db_backup.sh

# Cek hasil backup
ls -la /var/backups/databases/
```

### Test Cronjob
```bash
# Cek cronjob yang aktif
sudo crontab -l

# Cek log cron
tail -f /var/log/syslog | grep CRON
```

## Troubleshooting

### Permission Issues
```bash
# Pastikan script memiliki permission execute
sudo chmod +x /usr/local/bin/db_backup.sh

# Pastikan direktori backup dapat diakses
sudo chown root:root /var/backups/databases
sudo chmod 755 /var/backups/databases
```

### Database Connection Issues
```bash
# Test koneksi MySQL
mysql -u root -p -h 162.11.0.232 -P 3306

# Test koneksi PostgreSQL
PGPASSWORD='pgpass' psql -U sharedpg -h localhost
```

### Disk Space
```bash
# Cek space disk
df -h

# Cek ukuran backup
du -sh /var/backups/databases/
```

### Google Drive Issues
```bash
# Cek konfigurasi rclone
rclone config show gdrive

# Test koneksi Google Drive
rclone lsd gdrive:

# Cek space Google Drive
rclone about gdrive:

# Test upload manual
echo "test" > test.txt
rclone copy test.txt gdrive:/
rclone ls gdrive: | grep test.txt
rclone delete gdrive:/test.txt
rm test.txt
```

## Restore Database

### Restore MySQL
```bash
# Restore database dari file backup
mysql -u root -p -h 162.11.0.232 -P 3306 db_asset_it < db_asset_it_01_12_2024.sql
```

### Restore PostgreSQL
```bash
# Restore database dari file backup
PGPASSWORD='pgpass' psql -U sharedpg -h localhost core-api-cum < core-api-cum_01_12_2024.sql
```

### Download dari Google Drive
```bash
# Download backup dari Google Drive
rclone copy gdrive:/db_asset_it_01_12_2024.sql ./

# List semua backup di Google Drive
rclone ls gdrive: | grep $(date +%d_%m_%Y)
```

## Maintenance

### Cleanup Manual
```bash
# Hapus backup lebih dari 7 hari
find /var/backups/databases -type d -name "*_*_*" -mtime +7 -exec rm -rf {} \;

# Hapus log lama
find /var/log -name "db_backup.log*" -mtime +30 -delete
```

### Cleanup Google Drive
```bash
# Hapus backup lama di Google Drive (lebih dari 30 hari)
rclone lsf gdrive: | grep -E "[0-9]{2}_[0-9]{2}_[0-9]{4}" | while read file; do
    # Logic untuk hapus file lama di Google Drive
    echo "Checking: $file"
done

# Atau hapus manual berdasarkan tanggal
rclone delete gdrive:/db_asset_it_01_11_2024.sql  # Contoh hapus backup lama
```

### Monitoring Space
```bash
# Script untuk monitoring space backup lokal
#!/bin/bash
BACKUP_SIZE=$(du -sh /var/backups/databases | cut -f1)
echo "Total backup size: $BACKUP_SIZE"
echo "Backup count: $(find /var/backups/databases -type d -name "*_*_*" | wc -l)"

# Monitoring space Google Drive
rclone about gdrive:
rclone size gdrive:/
```

## Fitur Auto-Detect Database

Script ini akan secara otomatis mendeteksi semua database yang ada di server:

### MySQL
- Mendeteksi semua database kecuali system databases (`information_schema`, `performance_schema`, `mysql`, `sys`)
- Menggunakan koneksi yang dikonfigurasi di script

### PostgreSQL  
- Mendeteksi semua database kecuali system databases (`template0`, `template1`, `postgres`)
- Menggunakan koneksi yang dikonfigurasi di script

### Keuntungan
- **Tidak perlu konfigurasi manual** database list
- **Otomatis backup database baru** yang ditambahkan
- **Tidak ada database yang terlewat** dalam backup

## Format File Backup

### Nama File
- **Format**: `nama_database_dd_mm_yyyy.sql`
- **Contoh**: `db_asset_it_01_12_2024.sql`
- **Lokasi**: `/var/backups/databases/dd_mm_yyyy/`

### Struktur Folder
```
/var/backups/databases/
├── 01_12_2024/
│   ├── db_asset_it_01_12_2024.sql
│   ├── core-api-cum_01_12_2024.sql
│   └── database2_01_12_2024.sql
├── 02_12_2024/
│   ├── db_asset_it_02_12_2024.sql
│   └── core-api-cum_02_12_2024.sql
└── ...
```

### Keuntungan Format
- **Mudah dibaca** tanggal backup
- **Tidak perlu kompresi** - file langsung SQL
- **Upload cepat** ke Google Drive
- **Restore mudah** tanpa decompress

## Google Drive Setup

Untuk setup Google Drive yang lebih detail, lihat file `GOOGLE_DRIVE_SETUP.md` yang berisi:
- Instalasi rclone
- Konfigurasi Google Drive
- Troubleshooting
- Monitoring dan maintenance

## File yang Dibuat

Setelah menjalankan script, Anda akan mendapatkan:
- **File backup**: `nama_database_dd_mm_yyyy.sql` di `/var/backups/databases/dd_mm_yyyy/`
- **Upload otomatis**: File backup akan diupload ke Google Drive
- **Log file**: `/var/log/db_backup.log` untuk monitoring proses

## Ringkasan Fitur

✅ **Auto-detect semua database** MySQL dan PostgreSQL  
✅ **Format nama file**: `nama_database_dd_mm_yyyy.sql`  
✅ **Upload otomatis ke Google Drive** menggunakan rclone  
✅ **Logging lengkap** proses backup  
✅ **Cleanup backup lama** (lebih dari 7 hari)  
✅ **Tidak perlu kompresi** - file langsung SQL  
✅ **Restore mudah** tanpa decompress  
✅ **Monitoring space** lokal dan Google Drive  

## Support

Jika mengalami masalah, cek:
1. **Log file**: `/var/log/db_backup.log`
2. **Konfigurasi rclone**: `rclone config show gdrive`
3. **Status koneksi**: `rclone lsd gdrive:`
4. **Space Google Drive**: `rclone about gdrive:`
5. **Dokumentasi Google Drive**: `GOOGLE_DRIVE_SETUP.md`
