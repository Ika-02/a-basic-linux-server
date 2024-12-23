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
gum confirm || exit 0
gum log --time rfc822 --structured --level info "Deleting '$name' as a user..."
sudo rm -rf ${web_directory}/$name
sudo find / -user $name -delete
sudo userdel $name
sudo rm /etc/httpd/conf.d/$name.conf
sudo sed -i "/${name}\ IN\ CNAME\ ${hostname}/d" /var/named/$domain.zone
sudo sed -i "/www.${name}\ IN\ CNAME\ ${hostname}/d" /var/named/$domain.zone
sudo systemctl restart httpd.service
sudo systemctl restart named.service
rootpass=$(gum input --password --prompt "Enter DB password: ")
mysql -uroot -p${rootpass} -e "DROP DATABASE $name;"
mysql -uroot -p${rootpass} -e "DROP USER '$name'@'localhost';"

gum log --time rfc822 --structured --level info "User '$name' has been deleted."
exit 0