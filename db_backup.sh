#!/bin/bash

# Database Backup Script untuk MySQL dan PostgreSQL
# Script ini akan membuat backup untuk semua database yang dikonfigurasi
# Setiap database akan disimpan dalam file terpisah dengan timestamp
#    sudo chmod +x /usr/local/bin/db_backup.sh
#    sudo crontab -e
# Tambahkan: 0 2 * * * /usr/local/bin/db_backup.sh

# Konfigurasi umum
BACKUP_BASE_DIR="/var/backups/databases"
LOG_FILE="/var/log/db_backup.log"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${BACKUP_BASE_DIR}/${DATE}"

# Konfigurasi MySQL
MYSQL_HOST="162.11.0.232"
MYSQL_PORT="3306"
MYSQL_USER="root"
MYSQL_PASSWORD="your_mysql_password"
MYSQL_DATABASES=("db_asset_it" "database2" "database3")  # Tambahkan database MySQL lainnya

# Konfigurasi PostgreSQL
PG_HOST="localhost"
PG_USER="sharedpg"
PG_PASSWORD="pgpass"
PG_DATABASES=("core-api-cum" "database2" "database3")  # Tambahkan database PostgreSQL lainnya

# Fungsi untuk logging
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Fungsi untuk membuat direktori backup
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log_message "Direktori backup dibuat: $BACKUP_DIR"
    fi
}

# Fungsi untuk backup MySQL
backup_mysql() {
    log_message "Memulai backup MySQL..."
    
    for db in "${MYSQL_DATABASES[@]}"; do
        log_message "Backup database MySQL: $db"
        
        # Export database MySQL
        if mysqldump -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -P "$MYSQL_PORT" -h "$MYSQL_HOST" "$db" > "${BACKUP_DIR}/${db}_mysql.sql" 2>>"$LOG_FILE"; then
            log_message "✓ Backup MySQL berhasil: $db"
            
            # Kompres file backup
            gzip "${BACKUP_DIR}/${db}_mysql.sql"
            log_message "✓ File dikompres: ${db}_mysql.sql.gz"
        else
            log_message "✗ Error backup MySQL: $db"
        fi
    done
}

# Fungsi untuk backup PostgreSQL
backup_postgresql() {
    log_message "Memulai backup PostgreSQL..."
    
    # Set environment variable untuk password
    export PGPASSWORD="$PG_PASSWORD"
    
    for db in "${PG_DATABASES[@]}"; do
        log_message "Backup database PostgreSQL: $db"
        
        # Export database PostgreSQL
        if pg_dump -U "$PG_USER" -h "$PG_HOST" -F p -f "${BACKUP_DIR}/${db}_postgresql.sql" "$db" 2>>"$LOG_FILE"; then
            log_message "✓ Backup PostgreSQL berhasil: $db"
            
            # Kompres file backup
            gzip "${BACKUP_DIR}/${db}_postgresql.sql"
            log_message "✓ File dikompres: ${db}_postgresql.sql.gz"
        else
            log_message "✗ Error backup PostgreSQL: $db"
        fi
    done
    
    # Unset password environment variable
    unset PGPASSWORD
}

# Fungsi untuk cleanup backup lama (opsional)
cleanup_old_backups() {
    log_message "Membersihkan backup lama (lebih dari 7 hari)..."
    
    # Hapus backup yang lebih dari 7 hari
    find "$BACKUP_BASE_DIR" -type d -name "20*" -mtime +7 -exec rm -rf {} \; 2>/dev/null
    
    log_message "Cleanup backup lama selesai"
}

# Fungsi untuk menampilkan informasi backup
show_backup_info() {
    log_message "=== INFORMASI BACKUP ==="
    log_message "Tanggal backup: $(date)"
    log_message "Direktori backup: $BACKUP_DIR"
    log_message "Ukuran backup: $(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)"
    log_message "Jumlah file: $(find "$BACKUP_DIR" -name "*.gz" | wc -l)"
    log_message "========================"
}

# Main execution
main() {
    log_message "=== MULAI PROSES BACKUP DATABASE ==="
    
    # Buat direktori backup
    create_backup_dir
    
    # Backup MySQL
    if [ ${#MYSQL_DATABASES[@]} -gt 0 ]; then
        backup_mysql
    else
        log_message "Tidak ada database MySQL yang dikonfigurasi"
    fi
    
    # Backup PostgreSQL
    if [ ${#PG_DATABASES[@]} -gt 0 ]; then
        backup_postgresql
    else
        log_message "Tidak ada database PostgreSQL yang dikonfigurasi"
    fi
    
    # Tampilkan informasi backup
    show_backup_info
    
    # Cleanup backup lama
    cleanup_old_backups
    
    log_message "=== PROSES BACKUP SELESAI ==="
}

# Jalankan script
main "$@"
