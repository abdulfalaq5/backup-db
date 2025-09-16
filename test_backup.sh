#!/bin/bash

# Script untuk testing database backup
# Jalankan script ini untuk memastikan semua fungsi bekerja dengan baik

echo "=== TESTING DATABASE BACKUP SCRIPT ==="
echo "Tanggal: $(date)"
echo ""

# Cek apakah script backup ada
if [ ! -f "/usr/local/bin/db_backup.sh" ]; then
    echo "❌ Script backup tidak ditemukan di /usr/local/bin/db_backup.sh"
    echo "   Pastikan script sudah diinstall dengan benar"
    exit 1
else
    echo "✅ Script backup ditemukan"
fi

# Cek permission script
if [ ! -x "/usr/local/bin/db_backup.sh" ]; then
    echo "❌ Script backup tidak memiliki permission execute"
    echo "   Jalankan: sudo chmod +x /usr/local/bin/db_backup.sh"
    exit 1
else
    echo "✅ Script backup memiliki permission execute"
fi

# Cek direktori backup
if [ ! -d "/var/backups/databases" ]; then
    echo "❌ Direktori backup tidak ditemukan"
    echo "   Jalankan: sudo mkdir -p /var/backups/databases"
    exit 1
else
    echo "✅ Direktori backup ditemukan"
fi

# Cek permission direktori backup
if [ ! -w "/var/backups/databases" ]; then
    echo "❌ Tidak memiliki permission write ke direktori backup"
    echo "   Jalankan: sudo chown root:root /var/backups/databases"
    exit 1
else
    echo "✅ Memiliki permission write ke direktori backup"
fi

# Cek log file
if [ ! -f "/var/log/db_backup.log" ]; then
    echo "⚠️  Log file belum ada (akan dibuat saat script dijalankan)"
else
    echo "✅ Log file ditemukan"
fi

# Cek apakah MySQL terinstall
if command -v mysql &> /dev/null; then
    echo "✅ MySQL client terinstall"
else
    echo "❌ MySQL client tidak terinstall"
    echo "   Install dengan: sudo apt install mysql-client"
fi

# Cek apakah PostgreSQL client terinstall
if command -v psql &> /dev/null; then
    echo "✅ PostgreSQL client terinstall"
else
    echo "❌ PostgreSQL client tidak terinstall"
    echo "   Install dengan: sudo apt install postgresql-client"
fi

# Cek apakah rclone terinstall
if command -v rclone &> /dev/null; then
    echo "✅ rclone terinstall"
    
    # Cek konfigurasi rclone
    if rclone listremotes | grep -q "gdrive"; then
        echo "✅ Konfigurasi Google Drive ditemukan"
    else
        echo "⚠️  Konfigurasi Google Drive belum ada"
        echo "   Jalankan: rclone config"
    fi
else
    echo "⚠️  rclone tidak terinstall (opsional untuk Google Drive)"
    echo "   Install dengan: curl https://rclone.org/install.sh | sudo bash"
fi

echo ""
echo "=== TESTING KONEKSI DATABASE ==="

# Test koneksi MySQL (jika dikonfigurasi)
if [ -f "/usr/local/bin/db_backup.sh" ]; then
    MYSQL_HOST=$(grep "MYSQL_HOST=" /usr/local/bin/db_backup.sh | cut -d'"' -f2)
    MYSQL_USER=$(grep "MYSQL_USER=" /usr/local/bin/db_backup.sh | cut -d'"' -f2)
    MYSQL_PASSWORD=$(grep "MYSQL_PASSWORD=" /usr/local/bin/db_backup.sh | cut -d'"' -f2)
    
    if [ "$MYSQL_PASSWORD" != "your_mysql_password" ]; then
        echo "Testing koneksi MySQL ke $MYSQL_HOST..."
        if mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -h "$MYSQL_HOST" -e "SELECT 1;" &>/dev/null; then
            echo "✅ Koneksi MySQL berhasil"
        else
            echo "❌ Koneksi MySQL gagal"
        fi
    else
        echo "⚠️  Password MySQL belum dikonfigurasi"
    fi
fi

# Test koneksi PostgreSQL (jika dikonfigurasi)
if [ -f "/usr/local/bin/db_backup.sh" ]; then
    PG_HOST=$(grep "PG_HOST=" /usr/local/bin/db_backup.sh | cut -d'"' -f2)
    PG_USER=$(grep "PG_USER=" /usr/local/bin/db_backup.sh | cut -d'"' -f2)
    PG_PASSWORD=$(grep "PG_PASSWORD=" /usr/local/bin/db_backup.sh | cut -d'"' -f2)
    
    if [ "$PG_PASSWORD" != "pgpass" ]; then
        echo "Testing koneksi PostgreSQL ke $PG_HOST..."
        if PGPASSWORD="$PG_PASSWORD" psql -U "$PG_USER" -h "$PG_HOST" -c "SELECT 1;" &>/dev/null; then
            echo "✅ Koneksi PostgreSQL berhasil"
        else
            echo "❌ Koneksi PostgreSQL gagal"
        fi
    else
        echo "⚠️  Password PostgreSQL belum dikonfigurasi"
    fi
fi

echo ""
echo "=== TESTING GOOGLE DRIVE ==="

# Test koneksi Google Drive
if command -v rclone &> /dev/null; then
    if rclone listremotes | grep -q "gdrive"; then
        echo "Testing koneksi Google Drive..."
        if rclone lsd gdrive: &>/dev/null; then
            echo "✅ Koneksi Google Drive berhasil"
        else
            echo "❌ Koneksi Google Drive gagal"
        fi
    else
        echo "⚠️  Konfigurasi Google Drive belum ada"
    fi
else
    echo "⚠️  rclone tidak terinstall"
fi

echo ""
echo "=== TESTING CRONJOB ==="

# Cek cronjob
if crontab -l 2>/dev/null | grep -q "db_backup.sh"; then
    echo "✅ Cronjob ditemukan:"
    crontab -l 2>/dev/null | grep "db_backup.sh"
else
    echo "⚠️  Cronjob belum dikonfigurasi"
    echo "   Jalankan: sudo crontab -e"
    echo "   Tambahkan: 0 2 * * * /usr/local/bin/db_backup.sh"
fi

echo ""
echo "=== RINGKASAN TESTING ==="
echo "Jika semua test berhasil, script backup siap digunakan."
echo "Untuk menjalankan backup manual:"
echo "  sudo /usr/local/bin/db_backup.sh"
echo ""
echo "Untuk monitoring log:"
echo "  tail -f /var/log/db_backup.log"
echo ""
echo "Untuk cek hasil backup:"
echo "  ls -la /var/backups/databases/\$(date +%d_%m_%Y)/"
echo ""
echo "=== TESTING SELESAI ==="
