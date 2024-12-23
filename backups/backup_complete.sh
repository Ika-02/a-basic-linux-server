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

# Variables
BACKUP_SOURCE="/"      # The source directory to backup
BACKUP_MOUNT_POINT="/mnt/backup/complete"     # The mount point for the backup disk
BACKUP_DISK="/dev/sdb"              # The backup disk 
BACKUP_DESTINATION="${BACKUP_MOUNT_POINT}/backup_$(date +%Y%m%d).tar"  # Backup destination with the current date

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

# Function to do the backup
perform_backup() {
    gum log --time rfc822 --structured --level info "Starting the full system backup to ${BACKUP_DESTINATION}..."

    # Create the backup
    tar -cvpzf "${BACKUP_DESTINATION}" --exclude=/proc --exclude=/tmp --exclude=/mnt --exclude=/dev --exclude=/sys --exclude=/run --exclude=/media --exclude=/lost+found --exclude="${BACKUP_MOUNT_POINT}" /

    if [ $? -ne 0 ]; then
        gum log --time rfc822 --structured --level error "Backup failed."
        exit 1
    fi
    gum log --time rfc822 --structured --level info "Backup completed successfully."
}

# Principal script
gum log --time rfc822 --structured --level info "Début du script de backup..."

mount_backup_disk

perform_backup

umount_backup_disk

gum log --time rfc822 --structured --level info "Script de backup terminé."
