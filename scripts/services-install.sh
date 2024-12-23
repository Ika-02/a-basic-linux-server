#!/bin/bash
function is_root() {
  if [ "$(id -u)" -eq 0 ];
  then
    return
  else # if not root user then ask for password
    sudo -v
  fi
}
is_root


# Remove unused packages
gum log --time rfc822 --structured --level info "Removing unused packages..."
sudo dnf remove -y cockpit cockpit-bridge cockpit-packagekit cockpit-podman cockpit-storaged cockpit-system cockpit-ws

# Install the services
gum log --time rfc822 --structured --level info "Installing services..."
sudo dnf install chrony -y
sudo dnf install samba samba-common samba-client nfs-utils vsftpd -y
sudo dnf install bind httpd httpd-tools php mod_ssl phpmyadmin -y
# sudo dnf install -y php-mysqlnd php-dom php-simplexml php-xml php-xmlreader php-curl php-exif php-ftp php-gd php-iconv php-json php-mbstring php-posix php-sockets php-tokenizer
sudo dnf install mysql-server -y
sudo dnf install fail2ban -y
sudo yum install clamav clamd -y

# Enable and start the services
gum log --time rfc822 --structured --level info "Enabling and starting the services..."
sudo systemctl enable --now chronyd.service
sudo systemctl enable --now {smb,vsftpd,nfs-server}.service
sudo systemctl enable --now {named,httpd,mysqld}.service
sudo systemctl enable --now {clamav-freshclam,fail2ban}.service

# Firewall
gum log --time rfc822 --structured --level info "Configuring the firewall..."
sudo firewall-cmd --add-service=ntp --permanent
sudo firewall-cmd --add-service={samba,ftp,rpc-bind,mountd,nfs} --permanent
sudo firewall-cmd --add-service={http,https,dns} --permanent
sudo firewall-cmd --remove-service=cockpit --permanent
sudo firewall-cmd --reload

# PHPMyAdmin
sudo mysql_secure_installation


printf "\n-----------------------------------\n"
gum log --time rfc822 --structured --level info "Services installed successfully."
exit 0