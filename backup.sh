#!/bin/bash
#
# InvoiceNinja v5 Docker Backup Script
#
# This script backs up the database, storage, and public directories.
# It creates a single compressed .tar.gz file and prunes old backups.
#

# --- Configuration ---
# Set these variables to match your environment.

# The names of your InvoiceNinja Docker containers
IN_APP_CONTAINER="debian-app-1"
IN_DB_CONTAINER="debian-mysql-1"

# Path to the .env file (update if needed)
ENV_FILE="/your/path/docker/invoiceninja/debian/.env"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: .env file not found at $ENV_FILE"
    echo "💡 Tip: Make sure the path is correct and the file exists"
    exit 1
fi

# Database credentials (should match your .env file)
DB_USERNAME=$(grep -oP 'DB_USERNAME=\K.*' "$ENV_FILE" | tr -d '"'"'")
DB_PASSWORD=$(grep -oP 'DB_PASSWORD=\K.*' "$ENV_FILE" | tr -d '"'"'")
DB_DATABASE=$(grep -oP 'DB_DATABASE=\K.*' "$ENV_FILE" | tr -d '"'"'")
DB_HOST=$(grep -oP 'DB_HOST=\K.*' "$ENV_FILE" | tr -d '"'"'")
DB_PORT=$(grep -oP 'DB_PORT=\K.*' "$ENV_FILE" | tr -d '"'"'")

# Verify we have all required credentials
if [ -z "$DB_DATABASE" ] || [ -z "$DB_USERNAME" ] || [ -z "$DB_PASSWORD" ]; then
    echo "❌ Error: Could not extract all required database credentials from .env file"
    echo "Found values:"
    echo "  DB_HOST: $DB_HOST"
    echo "  DB_PORT: $DB_PORT"
    echo "  DB_DATABASE: $DB_DATABASE"
    echo "  DB_USERNAME: $DB_USERNAME"
    echo "  DB_PASSWORD: [hidden]"
    exit 1
fi

echo "✅ Successfully extracted database credentials from .env"

# The directory on the HOST machine where backups will be stored
BACKUP_BASE_DIR="/mnt/data/invoiceninja"

# Number of days to keep backup files
KEEP_DAYS=7

# --- End of Configuration ---


# Exit script immediately if a command exits with a non-zero status.
set -e

# --- Script Execution ---

echo "🚀 Starting InvoiceNinja backup..."

# Create a timestamp for the backup file (e.g., 2025-08-27_233433)
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
# Define a temporary working directory for this specific backup
TEMP_DIR="$BACKUP_BASE_DIR/$TIMESTAMP"

# Create the backup directories
mkdir -p "$TEMP_DIR"
echo "✅ Backup directory created: $TEMP_DIR"

# 1. Back up the Database
# We use 'docker exec' to run mysqldump inside the DB container
# and stream the output directly to a compressed file on the host.
echo "⏳ Backing up the database..."
docker exec "$IN_DB_CONTAINER" mysqldump --no-tablespaces -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" | gzip > "$TEMP_DIR/db_backup.sql.gz"
echo "✅ Database backup complete."

# 2. Back up the Files
# We use 'docker cp' to copy the essential storage directories from
# the app container to our temporary backup directory on the host.
# 'storage' contains attached documents, invoices, logs, etc.
# 'public/storage' contains company logos and other public assets.
echo "⏳ Backing up files from the 'storage' directory..."
docker cp "$IN_APP_CONTAINER":/var/www/html/storage "$TEMP_DIR/storage"

echo "⏳ Backing up files from the 'public' directory..."
docker cp "$IN_APP_CONTAINER":/var/www/html/public "$TEMP_DIR/public"
echo "✅ File backup complete."

# 3. Create Final Compressed Archive
# We now create a single .tar.gz file containing all the backed-up components.
FINAL_ARCHIVE="$BACKUP_BASE_DIR/invoiceninja_backup_$TIMESTAMP.tar.gz"
echo "⏳ Creating final compressed archive..."
# The -C flag tells tar to change to that directory, ensuring clean paths in the archive
tar -czf "$FINAL_ARCHIVE" -C "$BACKUP_BASE_DIR" "$TIMESTAMP"
echo "✅ Archive created: $FINAL_ARCHIVE"

# 4. Cleanup
# Remove the temporary working directory.
echo "🧹 Cleaning up temporary files..."
rm -rf "$TEMP_DIR"
echo "✅ Cleanup complete."

# 5. Prune Old Backups
# Find and delete any backup archives older than the specified KEEP_DAYS.
echo "🗑️ Pruning old backups (older than $KEEP_DAYS days)..."
find "$BACKUP_BASE_DIR" -type f -name "*.tar.gz" -mtime +"$KEEP_DAYS" -delete
echo "✅ Pruning complete."

echo "🎉 Backup process finished successfully!"
