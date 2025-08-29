# InvoiceNinja_Backup_Script
Updated script for InvoiceNinja Backup

InvoiceNinja Docker Backup Script
This script provides a comprehensive backup solution for InvoiceNinja instances running in Docker containers. It backs up both the database and application files, creating compressed archives with automatic pruning of old backups.

Features
  🔐 Automatically extracts database credentials from InvoiceNinja's .env file
  🗄️ Backs up MySQL/MariaDB database with proper privilege handling
  📁 Archives application files (storage and public directories)
  🗑️ Automatically prunes backups older than specified days
  ✅ Includes validation and error checking
  📦 Creates compressed .tar.gz archives for efficient storage

Prerequisites
  InvoiceNinja v5 running in Docker containers
  Bash shell environment
  docker command line access
  Proper permissions to access the InvoiceNinja .env file

Installation
Clone or download this script to your server
Make the script executable:
```
  sudo chmod +x backsup.sh
```
Configuration
Edit the following variables in the script to match your environment:

```
# The names of your InvoiceNinja Docker containers
IN_APP_CONTAINER="debian-app-1"
IN_DB_CONTAINER="debian-mysql-1"

# Path to the .env file
ENV_FILE="$HOME/docker/invoiceninja/debian/.env"

# The directory on the HOST machine where backups will be stored
BACKUP_BASE_DIR="/mnt/data/invoiceninja"

# Number of days to keep backup files
KEEP_DAYS=7
```
Locating Your .env File
The script needs access to your InvoiceNinja .env file to extract database credentials. 
Common locations include:
  /docker/invoiceninja/debian    #This is considering you cloned invoiceninja to your server

Usage:
```
  sudo ./backup.sh
```
Script Explanation

1. Configuration Section
The script begins with configurable variables that you must set according to your environment.

2. .env File Processing
The script reads database credentials directly from your InvoiceNinja .env file, ensuring consistency with your application configuration.

3. Database Backup
Uses docker exec to run mysqldump inside the database container with the --no-tablespaces option to avoid privilege issues.

4. File Backup
Copies the essential directories from the application container:

   /var/www/html/storage - Contains invoices, documents, and application data

   /var/www/html/public - Contains public assets like logos and themes

5. Archive Creation
Creates a compressed .tar.gz file containing both the database dump and application files.

6. Cleanup
Removes temporary files and prunes backups older than the specified number of days.


Restoring From Backup
To restore from a backup:

Extract the archive:
```
  tar -xzf invoiceninja_backup_2025-01-01_020000.tar.gz
```

Restore the database:
```
  gunzip -c db_backup.sql.gz | sudo docker exec -i debian-mysql-1 mysql -u username -p database_name
```

Restore the files:
```
  sudo docker cp storage/. your-app-container:/var/www/html/storage/
  sudo docker cp public/. your-app-container:/var/www/html/public/
```

Set proper permissions:

```
  sudo docker exec debian-app-1 chown -R www-data:www-data /var/www/html/storage
  sudo docker exec debian-app-1 chown -R www-data:www-data /var/www/html/public
```

Pulling backup folder to remote system
```
  sudo rsync -avz username@ip address:/your/backup/path/invoiceninja /path/on/your/system
```

Change Owner and permissions
```
  sudo chown -R user:user /path/folder
```
