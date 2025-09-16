# Contoh Konfigurasi Database Backup

## Konfigurasi Script (db_backup.sh)

### Konfigurasi MySQL
```bash
MYSQL_HOST="localhost"              # Ganti dengan host MySQL Anda
MYSQL_PORT="3306"                   # Port MySQL
MYSQL_USER="root"                   # Username MySQL
MYSQL_PASSWORD="your_mysql_password" # Password MySQL
```

### Konfigurasi PostgreSQL
```bash
PG_HOST="localhost"                 # Host PostgreSQL
PG_USER="postgres"                  # Username PostgreSQL
PG_PASSWORD="your_pg_password"      # Password PostgreSQL
```

### Konfigurasi Google Drive
```bash
ENABLE_GOOGLE_DRIVE_UPLOAD=true
GOOGLE_DRIVE_FOLDER_ID=""           # ID folder Google Drive (kosongkan untuk root)
RCLONE_CONFIG_NAME="gdrive"         # Nama konfigurasi rclone
```

## Contoh Crontab

### Backup Harian
```bash
# Backup setiap hari jam 2:00 AM
0 2 * * * /usr/local/bin/db_backup.sh
```

### Backup Setiap 6 Jam
```bash
# Backup setiap 6 jam
0 */6 * * * /usr/local/bin/db_backup.sh
```

### Backup Hari Kerja
```bash
# Backup setiap hari kerja (Senin-Jumat) jam 1:00 AM
0 1 * * 1-5 /usr/local/bin/db_backup.sh
```

### Backup Mingguan
```bash
# Backup setiap minggu pada hari Minggu jam 3:00 AM
0 3 * * 0 /usr/local/bin/db_backup.sh
```

## Contoh Output File

### Format Nama File
- `db_asset_it_01_12_2024.sql`
- `core-api-cum_01_12_2024.sql`
- `database2_01_12_2024.sql`

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

## Contoh Log Output

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

## Contoh Restore

### Restore MySQL
```bash
# Restore database dari file backup
mysql -u root -p -h localhost -P 3306 db_asset_it < db_asset_it_01_12_2024.sql
```

### Restore PostgreSQL
```bash
# Restore database dari file backup
PGPASSWORD='your_pg_password' psql -U postgres -h localhost db_asset_it < db_asset_it_01_12_2024.sql
```

### Download dari Google Drive
```bash
# Download backup dari Google Drive
rclone copy gdrive:/db_asset_it_01_12_2024.sql ./

# List semua backup di Google Drive
rclone ls gdrive: | grep $(date +%d_%m_%Y)
```

## Contoh Monitoring

### Cek Status Backup
```bash
# Cek log terbaru
tail -f /var/log/db_backup.log

# Cek file backup hari ini
ls -la /var/backups/databases/$(date +%d_%m_%Y)/

# Cek space backup
du -sh /var/backups/databases/
```

### Cek Google Drive
```bash
# Cek space Google Drive
rclone about gdrive:

# Cek file backup di Google Drive
rclone ls gdrive: | grep $(date +%d_%m_%Y)

# Cek konfigurasi rclone
rclone config show gdrive
```

## Troubleshooting

### Error Koneksi Database
```bash
# Test koneksi MySQL
mysql -u root -p -h localhost -P 3306

# Test koneksi PostgreSQL
PGPASSWORD='your_pg_password' psql -U postgres -h localhost
```

### Error Google Drive
```bash
# Test koneksi Google Drive
rclone lsd gdrive:

# Re-authenticate
rclone config reconnect gdrive:
```

### Error Permission
```bash
# Pastikan script memiliki permission execute
sudo chmod +x /usr/local/bin/db_backup.sh

# Pastikan direktori backup dapat diakses
sudo chown root:root /var/backups/databases
sudo chmod 755 /var/backups/databases
```
