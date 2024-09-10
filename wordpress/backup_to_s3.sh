#!/bin/bash
TIMESTAMP=$(date +"%F")
BACKUP_DIR="/var/www/backup"
WP_PATH="/var/www/vhosts/pradeeptech.info"
DB_USER="main_admin"
DB_NAME="main_wordpress"
DB_PASSWORD="Kishor@1234" 



# Backup WordPress files
zip -r $BACKUP_DIR/wordpress-files-backup-$TIMESTAMP.zip $WP_PATH

# Backup WordPress database (include the password in the command)
mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME > $BACKUP_DIR/wordpress-db-backup-$TIMESTAMP.sql
gzip $BACKUP_DIR/wordpress-db-backup-$TIMESTAMP.sql

# Upload to S3
aws s3 cp $BACKUP_DIR/wordpress-files-backup-$TIMESTAMP.zip s3://wp-backup-al/backup/
aws s3 cp $BACKUP_DIR/wordpress-db-backup-$TIMESTAMP.sql.gz s3://wp-backup-al/backup/
