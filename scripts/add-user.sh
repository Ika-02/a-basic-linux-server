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

# Importing config
sed -i 's/\r//g' services.conf
. services.conf


name=$(gum input --prompt "Enter name: ")

if grep "${name}" /etc/passwd >/dev/null 2>&1; then
  gum log --structured --level error "User '$name' already exists."
  exit 1
fi

pass=$(gum input --password --prompt "Enter password: ")
pass2=$(gum input --password --prompt "Confirm password: ")

if [ "$pass" != "$pass2" ]; then
  gum log --structured --level error "Passwords do not match."
  exit 1
fi

gum log --time rfc822 --structured --level info "Adding '$name' as a new user..."
# Add the user with a home directory and a nologin shell
sudo useradd -m -d "${web_directory}/${name}" -p "${pass}" -s /usr/sbin/nologin $name
echo "${name}:${pass}" | sudo chpasswd
soft_quota=$(($quota * 3 / 4)) # 75% of the quota
sudo xfs_quota -x -c "limit bsoft=${soft_quota}m bhard=${quota}m ${name}" $web_directory

# FTP [DONE]
gum log --time rfc822 --structured --level info "Configuring the FTP service..."
sudo echo $name >> /etc/vsftpd/user_list

# Samba [DONE]
gum log --time rfc822 --structured --level info "Configuring the Samba service..."
(echo "$pass"; sleep 1; echo "$pass") | sudo smbpasswd -s -a $name
sudo echo "[$name]
path = ${web_directory}/${name}
valid users = $name
read only = no
browsable = yes
writable = yes
guest ok = no" >> /etc/samba/smb.conf
sudo systemctl restart smb

# DNS [DONE]
gum log --time rfc822 --structured --level info "Configuring the DNS service..."
sudo echo "${name} IN CNAME ${hostname}
www.${name} IN CNAME ${hostname}" >> "/var/named/${domain}.zone"
sudo sed -i -e "s/[0-9]\{10\}/$(date +%10s)/" /var/named/${domain}.zone
sudo systemctl restart named

# Web [DONE]
gum log --time rfc822 --structured --level info "Configuring the Web service..."
sudo chmod g+s "${web_directory}/${name}"
#sudo semanage fcontext -a -t httpd_sys_content_t "${web_directory}/${name}"
#sudo restorecon -Rv "${web_directory}/${name}"
sudo sed -i "s/John Doe/${name}/g" "${web_directory}/${name}/index.php"
sudo chown -R $name:apache "${web_directory}/${name}"
sudo chmod -R 750 "${web_directory}/${name}"
sudo semanage fcontext -a -t public_content_rw_t "${web_directory}/${name}(/.*)?"
sudo restorecon -Rv "${web_directory}/${name}"
sudo mkdir -p "${web_directory}/${name}/.crt"
sudo semanage fcontext -a -t cert_t "${web_directory}/${name}/.crt(/.*)?"
sudo restorecon -Rv "${web_directory}/${name}/.crt"
sudo openssl req -newkey rsa:2048 -nodes -keyout "${web_directory}/${name}/.crt/${name}.local-key.pem" -x509 -days 365 -out "${web_directory}/${name}/.crt/${name}.local.pem" -subj "/C=BE/ST=Brussels/L=Brussels/O=42/OU=42/CN=${hostname}"
sudo echo "
<VirtualHost *:80>
  ServerName ${name}.${domain}
  ServerAlias www.${name}.${domain}
  Redirect permanent / https://www.${name}.${domain}/ 
</VirtualHost>

<VirtualHost *:443>
    ServerName www.${name}.${domain}
    DocumentRoot ${web_directory}/${name}
    <Directory ${web_directory}/${name}>
      Options +FollowSymlinks
      AllowOverride All
      Require all granted
    </Directory>
    ErrorLog /var/log/httpd/${name}-error.log
    CustomLog /var/log/httpd/${name}-access.log combined
    SSLEngine On
    SSLCertificateFile "${web_directory}/${name}/.crt/${name}.local.pem"
    SSLCertificateKeyFile "${web_directory}/${name}/.crt/${name}.local-key.pem"
</VirtualHost>
" > /etc/httpd/conf.d/${name}.conf
sudo apachectl -k graceful

# MySQL [DONE]
gum log --time rfc822 --structured --level info "Configuring the MySQL service..."
rootpass=$(gum input --password --prompt "Enter DB password: ")
if [ -f /root/.my.cnf ]; then
  mysql -e "CREATE DATABASE IF NOT EXISTS ${name};"
  mysql -e "CREATE USER ${name}@'localhost' IDENTIFIED BY '${pass}';"
  mysql -e "GRANT ALL PRIVILEGES ON ${name}. TO ${name};"
  mysql -e "FLUSH PRIVILEGES;"
else
  mysql -uroot -p${rootpass} -e "CREATE DATABASE IF NOT EXISTS ${name};"  2>/dev/null
  mysql -uroot -p${rootpass} -e "CREATE USER ${name}@'localhost' IDENTIFIED BY '${pass}';" 2>/dev/null
  mysql -uroot -p${rootpass} -e "GRANT ALL PRIVILEGES ON ${name}.* TO ${name}@'localhost';" 2>/dev/null
  mysql -uroot -p${rootpass} -e "FLUSH PRIVILEGES;" 2>/dev/null
  mysql -uroot -p${rootpass} -e "SHOW GRANTS FOR ${name}@'localhost';" 2>/dev/null
fi

printf "\n-----------------------------------\n"
gum log --time rfc822 --structured --level info "User '$name' added successfully."
exit 0