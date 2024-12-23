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


gum confirm || exit 0
gum log --time rfc822 --structured --level info "SSH Policies Hardening..."
sudo semanage port -a -t ssh_port_t -p tcp $ssh_port
sudo firewall-cmd --add-port=$ssh_port/tcp --permanent
sudo firewall-cmd --reload
sudo echo "# SSH Hardening
Protocol 2
Port ${ssh_port}
PermitRootLogin no
PasswordAuthentication no
LoginGraceTime 30
ClientAliveInterval 10
LogLevel VERBOSE
X11Forwarding no
" > /etc/ssh/sshd_config.d/ssh-hardening.conf
sudo systemctl restart sshd

gum log --time rfc822 --structured --level info "[DONE]"
exit 0
