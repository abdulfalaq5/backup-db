# Database Backup System

Sistem backup otomatis untuk database MySQL dan PostgreSQL dengan upload ke Google Drive.

## 🚀 Fitur Utama

✅ **Auto-detect semua database** MySQL dan PostgreSQL  
✅ **Format nama file**: `nama_database_dd_mm_yyyy.sql`  
✅ **Upload otomatis ke Google Drive** menggunakan rclone  
✅ **Logging lengkap** proses backup  
✅ **Cleanup backup lama** (lebih dari 7 hari)  
✅ **Tidak perlu kompresi** - file langsung SQL  
✅ **Restore mudah** tanpa decompress  
✅ **Monitoring space** lokal dan Google Drive  

## 📁 File dalam Repository

### Script Utama
- **`db_backup.sh`** - Script backup utama yang sudah dimodifikasi sesuai kebutuhan
- **`test_backup.sh`** - Script untuk testing dan validasi sistem backup

### Dokumentasi
- **`README_backup.md`** - Panduan lengkap instalasi dan konfigurasi
- **`GOOGLE_DRIVE_SETUP.md`** - Panduan khusus setup Google Drive dengan rclone
- **`CONFIGURATION_EXAMPLES.md`** - Contoh konfigurasi dan penggunaan
- **`crontab_example.txt`** - Contoh konfigurasi cronjob

## 🛠️ Instalasi Cepat

### 1. Install Script
```bash
# Copy script ke sistem
sudo cp db_backup.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/db_backup.sh

# Buat direktori backup
sudo mkdir -p /var/backups/databases
sudo chown root:root /var/backups/databases
```

### 2. Konfigurasi Database
Edit file `/usr/local/bin/db_backup.sh` dan sesuaikan:
```bash
# Konfigurasi MySQL
MYSQL_HOST="localhost"
MYSQL_USER="root"
MYSQL_PASSWORD="your_mysql_password"

# Konfigurasi PostgreSQL
PG_HOST="localhost"
PG_USER="postgres"
PG_PASSWORD="your_pg_password"
```

### 3. Setup Google Drive (Opsional)
```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Konfigurasi Google Drive
rclone config
# Ikuti panduan di GOOGLE_DRIVE_SETUP.md
```

### 4. Setup Cronjob
```bash
sudo crontab -e
# Tambahkan: 0 2 * * * /usr/local/bin/db_backup.sh
```

### 5. Testing
```bash
# Jalankan script test
./test_backup.sh

# Test backup manual
sudo /usr/local/bin/db_backup.sh
```

## 📋 Format File Backup

### Nama File
- **Format**: `nama_database_dd_mm_yyyy.sql`
- **Contoh**: `db_asset_it_01_12_2024.sql`

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

## 🔧 Konfigurasi

### Auto-Detect Database
Script akan otomatis mendeteksi semua database:
- **MySQL**: Exclude system databases (`information_schema`, `performance_schema`, `mysql`, `sys`)
- **PostgreSQL**: Exclude system databases (`template0`, `template1`, `postgres`)

### Google Drive Upload
- File backup akan diupload otomatis ke Google Drive
- Menggunakan rclone untuk koneksi yang aman
- Support folder khusus atau root Google Drive

### Cleanup Otomatis
- Backup lokal lebih dari 7 hari akan dihapus
- Log file lebih dari 30 hari akan dihapus
- Google Drive backup dapat dikonfigurasi manual

## 📊 Monitoring

### Log File
- **Lokasi**: `/var/log/db_backup.log`
- **Format**: `[YYYY-MM-DD HH:MM:SS] pesan`

### Monitoring Commands
```bash
# Cek log terbaru
tail -f /var/log/db_backup.log

# Cek file backup hari ini
ls -la /var/backups/databases/$(date +%d_%m_%Y)/

# Cek space backup
du -sh /var/backups/databases/

# Cek Google Drive
rclone about gdrive:
rclone ls gdrive: | grep $(date +%d_%m_%Y)
```

## 🔄 Restore Database

### MySQL
```bash
mysql -u root -p -h localhost -P 3306 db_name < db_name_01_12_2024.sql
```

### PostgreSQL
```bash
PGPASSWORD='password' psql -U username -h localhost db_name < db_name_01_12_2024.sql
```

### Download dari Google Drive
```bash
rclone copy gdrive:/db_name_01_12_2024.sql ./
```

## 🚨 Troubleshooting

### Error Umum
1. **Permission denied**: `sudo chmod +x /usr/local/bin/db_backup.sh`
2. **Database connection failed**: Cek konfigurasi host, user, password
3. **Google Drive upload failed**: Cek konfigurasi rclone
4. **Cronjob tidak jalan**: Cek log cron dan permission

### Debug Commands
```bash
# Test koneksi database
mysql -u root -p -h localhost
PGPASSWORD='password' psql -U username -h localhost

# Test Google Drive
rclone lsd gdrive:

# Test script manual
sudo /usr/local/bin/db_backup.sh
```

## 📚 Dokumentasi Lengkap

- **`README_backup.md`** - Panduan instalasi dan konfigurasi lengkap
- **`GOOGLE_DRIVE_SETUP.md`** - Setup Google Drive step-by-step
- **`CONFIGURATION_EXAMPLES.md`** - Contoh konfigurasi dan penggunaan
- **`test_backup.sh`** - Script testing dan validasi

## 🆘 Support

Jika mengalami masalah:
1. Jalankan `./test_backup.sh` untuk diagnosa
2. Cek log file `/var/log/db_backup.log`
3. Baca dokumentasi lengkap di file README_backup.md
4. Cek troubleshooting di GOOGLE_DRIVE_SETUP.md

## 📝 Changelog

### v2.0 (Current)
- ✅ Format nama file: `nama_database_dd_mm_yyyy.sql`
- ✅ Auto-detect semua database
- ✅ Upload otomatis ke Google Drive
- ✅ Tidak perlu kompresi file
- ✅ Dokumentasi lengkap

### v1.0 (Previous)
- Format lama dengan kompresi
- Konfigurasi manual database
- Backup lokal saja
