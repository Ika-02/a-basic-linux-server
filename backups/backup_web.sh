#!/bin/bash

# Function to check if the user is root
function is_root() {
  if [ "$(id -u)" -eq 0 ]; then
    return
  else
    # If the user is not root, ask for the password
    sudo -v
  fi
}
is_root


BACKUP_SOURCE="/web"
BACKUP_DESTINATION="/mnt/backup/web"
LATEST_LINK="/mnt/backup/web/latest"

BACKUP_MOUNT_POINT="/mnt/backup"     # The mount point for the backup disk
BACKUP_DISK="/dev/sdb"              # The backup disk 

# Function to mount the disk
mount_backup_disk() {
    gum log --time rfc822 --structured --level info "Mounting the backup disk..."
    if mount | grep ${BACKUP_MOUNT_POINT} > /dev/null; then
        gum log --time rfc822 --structured --level warn "The backup disk is already mounted."
    else
        mount ${BACKUP_DISK} ${BACKUP_MOUNT_POINT}
        if [ $? -ne 0 ]; then
            gum log --time rfc822 --structured --level error "Failed to mount the backup disk."
            exit 1
        fi
    fi
}

# Function to unmount the disk
umount_backup_disk() {
    gum log --time rfc822 --structured --level info "Unmounting the backup disk..."
    umount ${BACKUP_MOUNT_POINT}
    if [ $? -ne 0 ]; then
        gum log --time rfc822 --structured --level error "Failed to unmount the backup disk."
        exit 1
    fi
}

perform_backup() {
    SNAPSHOT_FILE="${BACKUP_DESTINATION}/snapshot.snar"
    BACKUP_FILE="${BACKUP_DESTINATION}/backup_$(date '+%Y-%m-%d_%H%M%S').tar.gz"

    gum log --time rfc822 --structured --level info "Starting the incremental backup from ${BACKUP_SOURCE} to ${BACKUP_DESTINATION}..."
    # Create the backup
    tar -czf ${BACKUP_FILE} --listed-incremental=${SNAPSHOT_FILE} ${BACKUP_SOURCE} .
    if [ $? -ne 0 ]; then
        gum log --time rfc822 --structured --level error "Backup failed."
        exit 1
    fi
    gum log --time rfc822 --structured --level info "Backup completed successfully."

    # Delete old backups
    if [ "$(ls -D1t ${BACKUP_DESTINATION}/*.tar.gz | wc -l)" -gt 5 ]; then
        rm -f "$(ls -D1t ${BACKUP_DESTINATION}/*.tar.gz | tail -n 1)"
    fi
}


# Principal script
gum log --time rfc822 --structured --level info "Début du script de backup..."

mount_backup_disk

perform_backup

umount_backup_disk

gum log --time rfc822 --structured --level info "Script de backup terminé."

# Now, run the script with the following command:
# bash backup_test.sh
# ****************************************************************************************************
