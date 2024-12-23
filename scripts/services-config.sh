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

# Import the configuration
sed -i 's/\r//g' services.conf
. services.conf


# Chrony [DONE]
gum log --time rfc822 --structured --level info "Configuring the NTP service..."
sudo timedatectl set-timezone Europe/Brussels
sudo cp /etc/chrony.conf /etc/chrony.conf.backup
sudo sed -i "s/pool 2.rehl.pool.ntp.org iburst/#pool 2.rehl.pool.ntp.org iburst/g" /etc/chrony.conf
sudo echo "# Source NTP servers
server 0.be.pool.ntp.org iburst
server 1.be.pool.ntp.org iburst
server 2.be.pool.ntp.org iburst
server 3.be.pool.ntp.org iburst
# Allowed subnets
deny all
allow $subnet" >> /etc/chrony.conf
sudo timedatectl set-ntp true
sudo systemctl restart chronyd.service


# NFS [DONE]
gum log --time rfc822 --structured --level info "Configuring the NFS service..."
sudo mkdir -p "${share_directory}/public"
sudo chmod -R 755 "${share_directory}"
sudo chown -R  nobody:nobody "${share_directory}"
sudo cp /etc/exports /etc/exports.backup
if [ -z "$(grep "${share_directory}/public ${subnet}(rw,sync,no_subtree_check,all_squash,anonuid=65534,anongid=65534,insecure)" /etc/exports)" ]; then
  sudo echo "${share_directory}/public ${subnet}(rw,sync,no_subtree_check,all_squash,anonuid=65534,anongid=65534,insecure)" >> /etc/exports
fi
sudo exportfs -ar 
#mount -t nfs 192.168.1.7:/share/public /mnt


# Samba [DONE]
gum log --time rfc822 --structured --level info "Configuring the Samba service..."
sudo mkdir -p ${share_directory}/public
sudo chmod -R 777 ${share_directory}
sudo chown -R  nobody:nobody ${share_directory}
sudo chcon -Rt samba_share_t ${share_directory}
sudo xfs_quota -x -c "limit bsoft=16500m nobody" $share_directory
# xfs_quota -x -c 'report -h' /share
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
sudo echo "# Samba configuration
[global]
workgroup = WORKGROUP
server string = ${hostname} (Samba %v)
netbios name = ${hostname}
security = user
map to guest = bad user
dns proxy = no

[public]
path = ${share_directory}/public
public = yes
writable = yes
browsable = yes
guest ok = yes
read only = no
force user = nobody
force group = nobody
" > /etc/samba/smb.conf
sudo setsebool -P allow_smbd_anon_write on
sudo systemctl restart smb.service


# FTP [DONE]
gum log --time rfc822 --structured --level info "Configuring the FTP service..."
sudo cp /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.backup
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/tls/certs/vsftpd.pem -out /etc/pki/tls/certs/vsftpd.pem -subj "/C=BE/ST=Brussels/L=Brussels/O=42/OU=42/CN=${hostname}"
sudo echo "# FTP configuration
local_root=${web_directory}/$USER/
user_sub_token=$USER
write_enable=YES
local_enable=YES

# Security configuration
chroot_local_user=YES
allow_writeable_chroot=YES
pam_service_name=vsftpd
anonymous_enable=NO
userlist_enable=YES
userlist_deny=NO
hide_ids=YES

# SSL configuration
rsa_cert_file=/etc/pki/tls/certs/vsftpd.pem
rsa_private_key_file=/etc/pki/tls/certs/vsftpd.pem
ssl_enable=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES

# Passive mode ports configuration
pasv_enable=YES
pasv_min_port=60000
pasv_max_port=60050

# Logging
xferlog_enable=YES
xferlog_std_format=NO
xferlog_file=/var/log/vsftpd.log
log_ftp_protocol=YES
" > /etc/vsftpd/vsftpd.conf
sudo setsebool -P ftpd_full_access on
sudo echo "#%PAM-1.0
session    optional     pam_keyinit.so    force revoke
auth       required     pam_listfile.so item=user sense=deny file=/etc/vsftpd/ftpusers onerr=succeed
#auth       required     pam_shells.so
auth       include      password-auth
account    include      password-auth
session    required     pam_loginuid.so
session    include      password-auth
" > /etc/pam.d/vsftpd
sudo systemctl restart vsftpd.service
sudo firewall-cmd -q --add-port=60000-60050/tcp --permanent
sudo firewall-cmd --reload


# DNS [WORK IN PROGRESS - NEEDS TESTING]
gum log --time rfc822 --structured --level info "Configuring the DNS service..."
sudo cp /etc/named.conf /etc/named.conf.backup
sudo sed -i "s/127.0.0.1/${server_ip}/g" /etc/named.conf
sudo sed -i "s/localhost/any/g" /etc/named.conf
# Disable DNSSEC - for school network
sudo sed -i "s/dnssec-validation yes;/dnssec-validation no;/g" /etc/named.conf 
sudo echo "// Zones
zone \"${domain}\" IN {
  type master;
  file \"${domain}.zone\";
  allow-update { none; };
};

zone \"${inv_subnet}.in-addr.arpa\" IN {
  type master;
  file \"${inv_subnet}.zone\";
  allow-update { none; };
};" >> /etc/named.conf

timestamp=$(date +%10s)
sudo echo "\$TTL 1D
@ IN SOA ns1.${domain}. root.${domain}. (
  ${timestamp} ; serial
  1D ; refresh
  1H ; retry
  1W ; expire
  3H ) ; minimum

@ IN NS ns1
ns1 IN A ${server_ip}
${hostname} IN CNAME ns1
www IN CNAME ns1
" > "/var/named/${domain}.zone"

host_ip=$(echo $server_ip | cut -d'.' -f4)
sudo echo "\$TTL 1D
@ IN SOA ns1.${domain}. root.${domain}. (
  0 ; serial
  1D ; refresh
  1H ; retry
  1W ; expire
  3H ) ; minimum

@ IN NS ns1
ns1 IN A ${server_ip}
${host_ip} IN PTR ns1
" > "/var/named/${inv_subnet}.zone"
sudo systemctl restart named.service


# Apache [DONE]
gum log --time rfc822 --structured --level info "Configuring the Apache service..."
#setsebool -P allow_httpd_anon_write on
sudo setsebool -P httpd_can_network_connect on
sudo setsebool -P httpd_can_network_connect_db on
sudo cp index.php /etc/skel/index.php # Web template
sed -i "0,/Require local/s//Require all granted/" /etc/httpd/conf.d/phpMyAdmin.conf 
sudo echo "ServerName 127.0.0.1" >> /etc/httpd/conf/httpd.conf
sudo echo "<?php phpinfo(); ?>" > /var/www/html/index.php
sudo systemctl restart httpd.service


# MySQL [DONE]
gum log --time rfc822 --structured --level info "Configuring the MySQL service..."
sudo systemctl stop mysqld
sudo mkdir -p "${web_directory}/mysql-data"
sudo chown -R mysql:mysql "${web_directory}/mysql-data"
sudo cp -R -p /var/lib/mysql/* "${web_directory}/mysql-data"
sudo echo "[mysqld]
datadir=/web/mysql-data
socket=/web/mysql-data/mysql.sock
log-error=/var/log/mysql/mysqld.log
pid-file=/run/mysqld/mysqld.pid
" > /etc/my.cnf.d/mysql-server.cnf
sudo semanage fcontext -a -t mysqld_db_t "${web_directory}/mysql-data(/.*)?"
sudo chcon -Rt mysqld_db_t "${web_directory}/mysql-data"
sudo semanage fcontext -a -t mysqld_var_run_t "${web_directory}/mysql-data\.sock"
sudo restorecon -Rv ${web_directory}/mysql-data/mysql.sock
sudo ln -s /web/mysql-data/mysql.sock /var/lib/mysql/mysql.sock 
sudo sed -i "s/\$cfg\['Servers'\]\[\$i\]\['host'\] = 'localhost';/\$cfg\['Servers'\]\[\$i\]\['host'\] = '127.0.0.1';/g" /etc/phpMyAdmin/config.inc.php
sudo echo '$cfg['Servers'][$i]['AllowRoot'] = FALSE;' >> /etc/phpMyAdmin/config.inc.php
sudo systemctl restart mysqld
sudo systemctl restart httpd


# confid du fail2ban
gum log --time rfc822 --structured --level info "Configuring the fail2ban service....."
sudo echo "[DEFAULT]
ignoreip = 127.0.0.1 ${server_ip}
findtime = 5m
bantime = 36000
maxretry = 3

[sshd]
enabled = true
" > /etc/fail2ban/jail.d/perso.conf
sudo systemctl restart fail2ban


# Antivirus [DONE]
gum log --time rfc822 --structured --level info "Configuring the antivirus cron..."
sudo mkdir -p /share/quarantine
sudo chmod -R 600 /share/quarantine
sudo cp scan-antivirus.sh /etc/cron.daily/scan-antivirus.sh
sudo chmod +x /etc/cron.daily/scan-antivirus.sh


# Backups [IN TEST]
gum log --time rfc822 --structured --level info "Configuring the backups cron..."
sudo cp backup_web.sh /etc/cron.daily/backup_web.sh
sudo cp backup_var.sh /etc/cron.daily/backup_var.sh
sudo cp backup_share.sh /etc/cron.weekly/backup_share.sh
sudo cp backup_complete.sh /etc/cron.monthly/backup_complete.sh
sudo chmod +x /etc/cron.daily/*.sh
sudo chmod +x /etc/cron.weekly/*.sh
sudo chmod +x /etc/cron.monthly/*.sh


printf "\n-----------------------------------\n"
gum log --time rfc822 --structured --level info "Services configured successfully."
exit 0
