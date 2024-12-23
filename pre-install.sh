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

# Update system and install epel-release
printf "Updating system...\n"
sudo dnf update -y
sudo dnf upgrade -y
sudo subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y

# Installing homebrew
printf "Installing Gum...\n"
sudo dnf install curl -y
sudo dnf install $(curl https://api.github.com/repos/charmbracelet/gum/releases/latest | grep -Po '"browser_download_url":.*?[^\\]\.x86_64\.rpm"' | grep -Po 'https://.*?[^\\].rpm') -y
readonly GUM_VERSION=$(gum --version)
echo -e "-----------------------------------\n ${GUM_VERSION} installed successfully!"
exit 0