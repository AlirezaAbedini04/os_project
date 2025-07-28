#!/bin/bash

CONFIG_FILE="backup.conf"
LOG_FILE="backup.log"
ERROR_LOG="error.log"
RETENTION_DAYS=7
EMAIL_RECIPIENT="alirezaabedini119@gmail.com"  
ENCRYPTION_ENABLED=false
DRY_RUN=false

send_email() {
    local subject="$1"
    local body="$2"
    echo -e "$body" | mail -s "$subject" "$EMAIL_RECIPIENT"
}

perform_backup() {
    echo "Enter path to search for files:"
    read search_path
    echo "Enter file extension (e.g., txt, jpg):"
    read file_ext

    if [ ! -d "$search_path" ]; then
        echo "Path does not exist: $search_path"
        exit 1
    fi

    > "$CONFIG_FILE"
    find "$search_path" -type f -name "*.$file_ext" > "$CONFIG_FILE"

    if [ ! -s "$CONFIG_FILE" ]; then
        echo "No .$file_ext files found in $search_path"
        exit 1
    fi

    echo "Enter destination directory for backups:"
    read BACKUP_DIR
    mkdir -p "$BACKUP_DIR"

    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    ARCHIVE_NAME="backup_$TIMESTAMP.tar.gz"
    ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

    if [ "$DRY_RUN" = true ]; then
        echo " Dry-run mode: Files that would be backed up:"
        cat "$CONFIG_FILE"
        exit 0
    fi

    START_TIME=$(date +%s)
    tar -czf "$ARCHIVE_PATH" -T "$CONFIG_FILE" 2> "$ERROR_LOG"
    TAR_EXIT_CODE=$?
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    if [ $TAR_EXIT_CODE -eq 0 ]; then
        if [ "$ENCRYPTION_ENABLED" = true ]; then
            gpg --yes --batch --output "$ARCHIVE_PATH.gpg" --symmetric "$ARCHIVE_PATH"
            rm "$ARCHIVE_PATH"
            ARCHIVE_PATH="$ARCHIVE_PATH.gpg"
        fi

        FILE_SIZE=$(du -h "$ARCHIVE_PATH" | cut -f1)
        echo "[$(date)] SUCCESS | $ARCHIVE_NAME | Size: $FILE_SIZE | Time: ${DURATION}s" >> "$LOG_FILE"
        send_email "Backup Success" "Backup was created successfully: $ARCHIVE_PATH ($FILE_SIZE)"
        echo " Backup created: $ARCHIVE_PATH"
    else
        echo "[$(date)]  ERROR | Backup failed (see $ERROR_LOG)" >> "$LOG_FILE"
        send_email "Backup Failed" "Backup failed. Check $ERROR_LOG"
        echo "Backup failed. See $ERROR_LOG"
        exit 1
    fi

    echo "Removing backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -type f -name "backup_*.tar.gz*" -mtime +$RETENTION_DAYS -exec rm -v {} \; >> "$LOG_FILE"
    echo "[$(date)] Cleanup done" >> "$LOG_FILE"
}


while true; do
    echo ""
    echo "=========== BACKUP MENU ==========="
    echo "1) Perform backup"
    echo "2) Dry-run (preview files to be backed up)"
    echo "3) Toggle encryption (currently: $ENCRYPTION_ENABLED)"
    echo "4) Exit"
    echo "==================================="
    read -p "Select an option: " choice

    case $choice in
        1)
            DRY_RUN=false
            perform_backup
            ;;
        2)
            DRY_RUN=true
            perform_backup
            ;;
        3)
            if [ "$ENCRYPTION_ENABLED" = true ]; then
                ENCRYPTION_ENABLED=false
            else
                ENCRYPTION_ENABLED=true
            fi
            echo " Encryption is now: $ENCRYPTION_ENABLED"
            ;;
        4)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option. Try again."
            ;;
    esac
done
