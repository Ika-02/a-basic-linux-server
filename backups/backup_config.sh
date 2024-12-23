#!/bin/bash
function is_root() {
  if [ "$(id -u)" -eq 0 ]; then
    return
  else
    sudo -v # If the user is not root, ask for the password
  fi
}
is_root

# Import the configuration
sed -i 's/\r//g' services.conf
. services.conf


gum log --time rfc822 --structured --level info "Copying configuration files to the backup directory..."
sudo mkdir -p config_backup/etc
sudo cp -r /etc/* config_backup/etc/
sudo cp /var/named/$domain.zone config_backup/$domain.zone.backup
sudo cp /var/named/$inv_subnet.zone config_backup/$inv_subnet.zone.backup
sudo tar -czf config_backup.tar.gz config_backup
sudo rm -rf config_backup

gum log --time rfc822 --structured --level info "[DONE]"
exit 0