#!/bin/bash

LOG_FILE="backup.log"
ERROR_LOG="error.log"

read -p "Enter the path for backup: " search_path
read -p "Enter the format of the files(txt, jpg,..: " file_ext

if [ ! -d "$search_path" ]; then
    echo "path does not exist"
    exit 1
fi

config_file="backup.conf"
> "$config_file"  


find "$search_path" -type f -name "*.$file_ext" >> "$config_file"

if [ ! -s "$CONFIG_FILE" ]; then
    echo "No files with .$file_ext extension found in $search_path."
    exit 1
fi

echo "List of .$file_ext files in $search_path has been saved to $config_file."

read -p "Enter the destination directory for backups: " BACKUP_DIR

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVE_NAME="backup_$TIMESTAMP.tar.gz"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

START_TIME=$(date +%s)

tar -czf "$ARCHIVE_PATH" -T "$CONFIG_FILE" 2>"$ERROR_LOG"
TAR_EXIT_CODE=$?

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
