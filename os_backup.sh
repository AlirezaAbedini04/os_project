#!/bin/bash

CONFIG_FILE="backup.conf"
LOG_FILE="backup.log"
ERROR_LOG="error.log"
RETENTION_DAYS=7

read -p "Enter the path for backup: " search_path
read -p "Enter the format of the files (e.g., txt, jpg): " file_ext


if [ ! -d "$search_path" ]; then
    echo "Path does not exist: $search_path"
    exit 1
fi

# ========== FIND FILES ========== #
> "$CONFIG_FILE"
find "$search_path" -type f -name "*.$file_ext" > "$CONFIG_FILE"

if [ ! -s "$CONFIG_FILE" ]; then
    echo "No files with .$file_ext extension found in $search_path."
    exit 1
else
    echo "Found files listed in $CONFIG_FILE"
fi

read -p "Enter the destination directory for backups: " BACKUP_DIR
mkdir -p "$BACKUP_DIR"

# ========== CREATE ARCHIVE ========== #
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVE_NAME="backup_$TIMESTAMP.tar.gz"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

START_TIME=$(date +%s)

tar -czf "$ARCHIVE_PATH" -T "$CONFIG_FILE" 2> "$ERROR_LOG"
TAR_EXIT_CODE=$?

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# ========== LOG RESULT ========== #
if [ $TAR_EXIT_CODE -eq 0 ]; then
    FILE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
    echo "[$(date)] SUCCESS | File: $ARCHIVE_NAME | Size: $FILE_SIZE | Duration: ${DURATION}s" >> "$LOG_FILE"
    echo "Backup created successfully: $ARCHIVE_PATH"
else
    echo "[$(date)]  ERROR | Backup failed (see $ERROR_LOG)" >> "$LOG_FILE"
    echo " Backup failed. Check $ERROR_LOG for details."
    exit 1
fi

# ========== DELETE OLD BACKUPS ========== #
echo "Cleaning backups older than $RETENTION_DAYS days in $BACKUP_DIR..."
find "$BACKUP_DIR" -type f -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -exec rm -v {} \; >> "$LOG_FILE"
echo "[$(date)]  Cleanup complete: backups older than $RETENTION_DAYS days removed." >> "$LOG_FILE"

echo "All done."
