#!/bin/bash
. scripts/services.conf

while true;
do 
    gum style \
	--foreground 212 --border-foreground 212 --border double \
	--align center --width 50 --margin "1 2" --padding "2 4" \
	'Welcome to the launcher!' 'Please choose an option'

    # Menu options for the launcher
    choice=$(gum choose \
    "Exit" \
    "Add user" \
    "Remove user" \
    "Install" \
    "Configure" \
    "Display config" \
    "Edit config" \
    "SSH hardening" \
    "Manual antivirus scan" \
    "Manual config backup" \
    "Manual backup")

    # Case statement to handle the choice
    case $choice in
    "Install")
        bash scripts/services-install.sh;;
    "Configure")
        bash scripts/services-config.sh;;
    "Add user")
        bash scripts/add-user.sh;;
    "Remove user")
        bash scripts/rm-user.sh;;
    "SSH hardening")
        bash scripts/ssh-hardening.sh;;
    "Display config")
        gum pager < scripts/services.conf;;
    "Edit config")
        file=$(gum file .)
        nano "$file";;
    "Manual backup")
        bash backups/backups.sh;;
    "Manual config backup")
        bash backups/backup_config.sh;;
    "Manual antivirus scan")
        bash scripts/scan-antivirus.sh;;
    "Exit")
        clear
        exit 0;;
    esac
done