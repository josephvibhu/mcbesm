#!/bin/bash

mcbebak() {
    
# Set the world directory (update this path as per your setup)
world_directory="/home/user/minecraft/world"

# Set the remote Google Drive directory (replace 'mcbe' with your rclone remote name)
remote_name="mcserverbak"
backup_base_directory="$remote_name:/Minecraft_Backups"

# Ensure rclone is installed
if ! command -v rclone &> /dev/null; then
    echo "Error: rclone is not installed. Please install rclone, configure it as per the guide, and try again."
    exit 1
fi

# Confirm backup
read -p "Are you sure you want to back up the world '$world_name' (y/n)? " backup_choice
if [ "$backup_choice" != "y" ]; then
    echo "Backup skipped for '$world_name'."
    exit 0
fi

# Generate timestamp and backup directory
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
backup_directory="$backup_base_directory/$world_name-$timestamp"

echo "Backing up world '$world_name' to Google Drive..."
rclone copy "$world_directory" "$backup_directory" --progress || { 
    echo "Failed to back up '$world_name'. Check your rclone configuration or directory paths.";
    exit 1; 
}

echo "Backup completed successfully for '$world_name'."
}

