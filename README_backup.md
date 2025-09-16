# Database Backup Script - Panduan Instalasi dan Konfigurasi

## Deskripsi
Script ini digunakan untuk melakukan backup otomatis database MySQL dan PostgreSQL dengan fitur:
- Backup setiap database dalam file terpisah
- Pembuatan folder backup dengan timestamp
- Kompresi otomatis file backup
- Logging lengkap proses backup
- Cleanup backup lama (lebih dari 7 hari)

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
MYSQL_DATABASES=("db_asset_it" "database2" "database3")  # List database MySQL

# Konfigurasi PostgreSQL
PG_HOST="localhost"                 # Host PostgreSQL
PG_USER="sharedpg"                  # Username PostgreSQL
PG_PASSWORD="pgpass"                # Password PostgreSQL
PG_DATABASES=("core-api-cum" "database2" "database3")  # List database PostgreSQL
```

### 3. Setup Cronjob

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

Setiap backup akan membuat folder dengan format:
```
/var/backups/databases/
├── 20241201_020000/
│   ├── db_asset_it_mysql.sql.gz
│   ├── core-api-cum_postgresql.sql.gz
│   └── database2_mysql.sql.gz
├── 20241202_020000/
│   ├── db_asset_it_mysql.sql.gz
│   └── core-api-cum_postgresql.sql.gz
└── ...
```

## Monitoring dan Log

### Log File
Script akan membuat log di: `/var/log/db_backup.log`

### Contoh Log Output
```
[2024-12-01 02:00:01] === MULAI PROSES BACKUP DATABASE ===
[2024-12-01 02:00:01] Direktori backup dibuat: /var/backups/databases/20241201_020000
[2024-12-01 02:00:01] Memulai backup MySQL...
[2024-12-01 02:00:01] Backup database MySQL: db_asset_it
[2024-12-01 02:00:05] ✓ Backup MySQL berhasil: db_asset_it
[2024-12-01 02:00:05] ✓ File dikompres: db_asset_it_mysql.sql.gz
[2024-12-01 02:00:05] Memulai backup PostgreSQL...
[2024-12-01 02:00:05] Backup database PostgreSQL: core-api-cum
[2024-12-01 02:00:08] ✓ Backup PostgreSQL berhasil: core-api-cum
[2024-12-01 02:00:08] ✓ File dikompres: core-api-cum_postgresql.sql.gz
[2024-12-01 02:00:08] === INFORMASI BACKUP ===
[2024-12-01 02:00:08] Tanggal backup: Sun Dec  1 02:00:08 UTC 2024
[2024-12-01 02:00:08] Direktori backup: /var/backups/databases/20241201_020000
[2024-12-01 02:00:08] Ukuran backup: 15M
[2024-12-01 02:00:08] Jumlah file: 2
[2024-12-01 02:00:08] ========================
[2024-12-01 02:00:08] Membersihkan backup lama (lebih dari 7 hari)...
[2024-12-01 02:00:08] Cleanup backup lama selesai
[2024-12-01 02:00:08] === PROSES BACKUP SELESAI ===
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

## Restore Database

### Restore MySQL
```bash
# Decompress file
gunzip db_asset_it_mysql.sql.gz

# Restore database
mysql -u root -p -h 162.11.0.232 -P 3306 db_asset_it < db_asset_it_mysql.sql
```

### Restore PostgreSQL
```bash
# Decompress file
gunzip core-api-cum_postgresql.sql.gz

# Restore database
PGPASSWORD='pgpass' psql -U sharedpg -h localhost core-api-cum < core-api-cum_postgresql.sql
```

## Maintenance

### Cleanup Manual
```bash
# Hapus backup lebih dari 7 hari
find /var/backups/databases -type d -name "20*" -mtime +7 -exec rm -rf {} \;

# Hapus log lama
find /var/log -name "db_backup.log*" -mtime +30 -delete
```

### Monitoring Space
```bash
# Script untuk monitoring space backup
#!/bin/bash
BACKUP_SIZE=$(du -sh /var/backups/databases | cut -f1)
echo "Total backup size: $BACKUP_SIZE"
echo "Backup count: $(find /var/backups/databases -type d -name "20*" | wc -l)"
```
