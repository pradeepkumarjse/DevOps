#!/bin/bash

# MySQL credentials
USER="root"
PASSWORD="Kishor@1234"
OUTPUT_DIR="/Users/padeep/mysql-task/dump"
DATE=$(date +%F)
LOG_FILE="${OUTPUT_DIR}/backup_log_${DATE}.log"
HOST="localhost"

# Ensure the backup directory exists
if ! mkdir -p "$OUTPUT_DIR"; then
    echo "Error: Failed to create or access backup directory: $OUTPUT_DIR"
    exit 1
fi

# Start logging
echo "Backup started at $(date)" > "$LOG_FILE"
echo "---------------------------------------------------" >> "$LOG_FILE"

# Get a list of all databases (excluding system databases)
DATABASES=$(mysql --host="$HOST" --user="$USER" --password="$PASSWORD" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

# Check if the databases were retrieved successfully
if [ $? -ne 0 ] || [ -z "$DATABASES" ]; then
    echo "Error: Failed to retrieve database list or no databases available." | tee -a "$LOG_FILE"
    exit 1
fi

# Loop through each database and create a backup
for DB in $DATABASES; do
    BACKUP_FILE="${OUTPUT_DIR}/${DB}_backup_${DATE}.sql"
    echo "Backing up database: $DB" | tee -a "$LOG_FILE"

    # Perform the database backup and ensure output is only written if successful
    if mysqldump --user="$USER" --password="$PASSWORD" --databases "$DB" > "$BACKUP_FILE" 2>>"$LOG_FILE"; then
        echo "Backup of database $DB completed successfully: $BACKUP_FILE" | tee -a "$LOG_FILE"
    else
        echo "Backup of database $DB failed. Removing incomplete backup file if exists." | tee -a "$LOG_FILE"
        rm -f "$BACKUP_FILE" # Remove incomplete backup file
    fi
done

echo "---------------------------------------------------" >> "$LOG_FILE"
echo "Backup completed at $(date)" >> "$LOG_FILE"
