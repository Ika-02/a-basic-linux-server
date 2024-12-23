#!/bin/bash

# Chemin vers les scripts de sauvegarde
backup_share_script= bash backup_share.sh
backup_web_script= bash backup_web.sh
backup_complete_script= bash backup_complete.sh

# Fonction pour exécuter un script de sauvegarde

execute_backup_script() {
    script_path=$1
    if [ -x "$script_path" ]; then
        "$script_path"
    else
        echo "Le script $script_path n'existe pas ou n'est pas exécutable."
    fi
}


choice=$(gum choose \
    "Web files backup" \
    "Share files backup" \
    "Complete backup" \
    "Exit"
)


case $choice in
    "Web files backup")
        execute_backup_script "$backup_share_script"
        ;;
    "Share files backup")
        execute_backup_script "$backup_web_script"
        ;;
    "Complete backup")
        execute_backup_script "$backup_complete_script"
        ;;
    "Exit")
        clear
        exit 0
        ;;
esac