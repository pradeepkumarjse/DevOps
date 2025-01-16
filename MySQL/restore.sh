#!/bin/bash

# MySQL credentials
USER="root"
PASSWORD="Kishor@1234"
INPUT_DIR="/home/ubuntu/mysql-task"
LOG_FILE="${INPUT_DIR}/restore_log_$(date +%F).log"
DATE=$(date +%F)
HOST="localhost"

# Ensure the input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Directory $INPUT_DIR does not exist." | tee -a "$LOG_FILE"
    exit 1
fi

# Start logging
echo "Restore started at $(date)" > "$LOG_FILE"
echo "---------------------------------------------------" >> "$LOG_FILE"

# Find all .sql files matching the pattern
SQL_FILES=("$INPUT_DIR"/*_backup_"$DATE"*.sql)

# Check if any matching .sql files exist
if [ ! -e "${SQL_FILES[0]}" ]; then
    echo "Error: No .sql files found matching pattern *_backup_${DATE}*.sql in $INPUT_DIR." | tee -a "$LOG_FILE"
    exit 1
fi

# Loop through all matching .sql files
for SQL_FILE in "${SQL_FILES[@]}"; do
    echo "Processing file: $SQL_FILE" | tee -a "$LOG_FILE"

    # Execute the restore command and handle errors
    if mysql --host="$HOST" --user="$USER" --password="$PASSWORD" < "$SQL_FILE" 2>>"$LOG_FILE"; then
        echo "Successfully restored from $SQL_FILE." | tee -a "$LOG_FILE"
    else
        echo "Error: Failed to restore from $SQL_FILE." | tee -a "$LOG_FILE"
    fi
done

echo "---------------------------------------------------" >> "$LOG_FILE"
echo "Restore process completed at $(date)" >> "$LOG_FILE"
