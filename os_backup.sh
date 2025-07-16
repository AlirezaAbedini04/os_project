#!/bin/bash

read -p "Enter the path for backup: " search_path
read -p "Enter the format of the files(txt, jpg,..: " file_ext

if [ ! -d "$search_path" ]; then
    echo "path does not exist"
    exit 1
fi

config_file="backup.conf"
> "$config_file"  


find "$search_path" -type f -name "*.$file_ext" >> "$config_file"

echo "List of .$file_ext files in $search_path has been saved to $config_file."

read -p "Enter the destination directory for backups: " BACKUP_DIR

mkdir -p "$BACKUP_DIR"
