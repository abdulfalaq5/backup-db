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
DATE=$(date +%d_%m_%Y)
BACKUP_DIR="${BACKUP_BASE_DIR}/${DATE}"

# Konfigurasi MySQL
MYSQL_HOST="162.11.0.232"
MYSQL_PORT="3306"
MYSQL_USER="root"
MYSQL_PASSWORD="your_mysql_password"
# MYSQL_DATABASES akan diisi otomatis dengan semua database yang ada

# Konfigurasi PostgreSQL
PG_HOST="localhost"
PG_USER="sharedpg"
PG_PASSWORD="pgpass"
# PG_DATABASES akan diisi otomatis dengan semua database yang ada

# Konfigurasi Google Drive (opsional) - DINONAKTIFKAN
ENABLE_GOOGLE_DRIVE_UPLOAD=false
GOOGLE_DRIVE_FOLDER_ID=""  # ID folder Google Drive tujuan (kosongkan untuk root)
RCLONE_CONFIG_NAME="gdrive"  # Nama konfigurasi rclone

# Fungsi untuk logging
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Fungsi untuk auto-detect database MySQL
get_mysql_databases() {
    log_message "Mendeteksi database MySQL..."
    
    # Export password untuk mysql command
    export MYSQL_PWD="$MYSQL_PASSWORD"
    
    # Ambil list database (exclude system databases)
    MYSQL_DATABASES=($(mysql -u "$MYSQL_USER" -h "$MYSQL_HOST" -P "$MYSQL_PORT" -e "SHOW DATABASES;" | grep -v -E "^(Database|information_schema|performance_schema|mysql|sys)$"))
    
    # Unset password
    unset MYSQL_PWD
    
    log_message "Database MySQL ditemukan: ${MYSQL_DATABASES[*]}"
}

# Fungsi untuk auto-detect database PostgreSQL
get_postgresql_databases() {
    log_message "Mendeteksi database PostgreSQL..."
    
    # Export password untuk psql command
    export PGPASSWORD="$PG_PASSWORD"
    
    # Ambil list database (exclude system databases)
    PG_DATABASES=($(psql -U "$PG_USER" -h "$PG_HOST" -l -t | cut -d'|' -f1 | sed -e 's/^[[:space:]]*//' -e '/^$/d' | grep -v -E "^(template0|template1|postgres)$"))
    
    # Unset password
    unset PGPASSWORD
    
    log_message "Database PostgreSQL ditemukan: ${PG_DATABASES[*]}"
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
        
        # Format nama file: nama_database_dd_mm_yyyy.sql
        BACKUP_FILE="${BACKUP_DIR}/${db}_${DATE}.sql"
        
        # Export database MySQL
        if mysqldump -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -P "$MYSQL_PORT" -h "$MYSQL_HOST" "$db" > "$BACKUP_FILE" 2>>"$LOG_FILE"; then
            log_message "✓ Backup MySQL berhasil: $db"
            log_message "✓ File backup: $BACKUP_FILE"
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
        
        # Format nama file: nama_database_dd_mm_yyyy.sql
        BACKUP_FILE="${BACKUP_DIR}/${db}_${DATE}.sql"
        
        # Export database PostgreSQL
        if pg_dump -U "$PG_USER" -h "$PG_HOST" -F p -f "$BACKUP_FILE" "$db" 2>>"$LOG_FILE"; then
            log_message "✓ Backup PostgreSQL berhasil: $db"
            log_message "✓ File backup: $BACKUP_FILE"
        else
            log_message "✗ Error backup PostgreSQL: $db"
        fi
    done
    
    # Unset password environment variable
    unset PGPASSWORD
}

# Fungsi untuk upload ke Google Drive (DINONAKTIFKAN - backup hanya disimpan lokal)
upload_to_google_drive() {
    if [ "$ENABLE_GOOGLE_DRIVE_UPLOAD" = true ]; then
        log_message "Memulai upload ke Google Drive..."
        
        # Cek apakah rclone terinstall
        if ! command -v rclone &> /dev/null; then
            log_message "✗ rclone tidak ditemukan. Install rclone terlebih dahulu."
            return 1
        fi
        
        # Cek apakah konfigurasi rclone ada
        if ! rclone listremotes | grep -q "$RCLONE_CONFIG_NAME"; then
            log_message "✗ Konfigurasi rclone '$RCLONE_CONFIG_NAME' tidak ditemukan."
            log_message "Jalankan: rclone config untuk setup Google Drive"
            return 1
        fi
        
        # Upload setiap file backup
        for backup_file in "$BACKUP_DIR"/*.sql; do
            if [ -f "$backup_file" ]; then
                filename=$(basename "$backup_file")
                log_message "Uploading: $filename"
                
                if [ -n "$GOOGLE_DRIVE_FOLDER_ID" ]; then
                    # Upload ke folder tertentu
                    if rclone copy "$backup_file" "${RCLONE_CONFIG_NAME}:${GOOGLE_DRIVE_FOLDER_ID}/" --progress 2>>"$LOG_FILE"; then
                        log_message "✓ Upload berhasil: $filename"
                    else
                        log_message "✗ Upload gagal: $filename"
                    fi
                else
                    # Upload ke root Google Drive
                    if rclone copy "$backup_file" "${RCLONE_CONFIG_NAME}:/" --progress 2>>"$LOG_FILE"; then
                        log_message "✓ Upload berhasil: $filename"
                    else
                        log_message "✗ Upload gagal: $filename"
                    fi
                fi
            fi
        done
        
        log_message "Upload ke Google Drive selesai"
    else
        log_message "Upload ke Google Drive dinonaktifkan - backup hanya disimpan di server lokal"
        log_message "Lokasi backup: $BACKUP_DIR"
    fi
}

# Fungsi untuk cleanup backup lama (opsional)
cleanup_old_backups() {
    log_message "Membersihkan backup lama (lebih dari 7 hari)..."
    
    # Hapus backup yang lebih dari 7 hari
    find "$BACKUP_BASE_DIR" -type d -name "*_*_*" -mtime +7 -exec rm -rf {} \; 2>/dev/null
    
    log_message "Cleanup backup lama selesai"
}

# Fungsi untuk menampilkan informasi backup
show_backup_info() {
    log_message "=== INFORMASI BACKUP ==="
    log_message "Tanggal backup: $(date)"
    log_message "Direktori backup: $BACKUP_DIR"
    log_message "Ukuran backup: $(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)"
    log_message "Jumlah file: $(find "$BACKUP_DIR" -name "*.sql" | wc -l)"
    log_message "========================"
}

# Main execution
main() {
    log_message "=== MULAI PROSES BACKUP DATABASE ==="
    
    # Buat direktori backup
    create_backup_dir
    
    # Auto-detect database MySQL
    get_mysql_databases
    
    # Auto-detect database PostgreSQL
    get_postgresql_databases
    
    # Backup MySQL
    if [ ${#MYSQL_DATABASES[@]} -gt 0 ]; then
        backup_mysql
    else
        log_message "Tidak ada database MySQL yang ditemukan"
    fi
    
    # Backup PostgreSQL
    if [ ${#PG_DATABASES[@]} -gt 0 ]; then
        backup_postgresql
    else
        log_message "Tidak ada database PostgreSQL yang ditemukan"
    fi
    
    # Tampilkan informasi backup
    show_backup_info
    
    # Upload ke Google Drive
    upload_to_google_drive
    
    # Cleanup backup lama
    cleanup_old_backups
    
    log_message "=== PROSES BACKUP SELESAI ==="
}

# Jalankan script
main "$@"
