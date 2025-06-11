#!/bin/bash

# Check if the system is Debian
if ! grep -q "Debian" /etc/os-release; then
  echo "No action taken..."
  echo "Are you sure this is a Debian system?"
  exit 1
fi

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "No action taken..."
  echo "This script must be run as root."
  exit 1
fi

# Prompt for the new hostname
read -p "Enter desired hostname: " newHostname

echo "Generating new Machine ID..."
rm -f /var/lib/dbus/machine-id
rm -f /etc/machine-id
dbus-uuidgen --ensure=/etc/machine-id
ln -sf /etc/machine-id /var/lib/dbus/

echo "Generating SSH server keys..."

# Generate SSH host keys if they do not exist or recreate them
for key_type in rsa dsa ecdsa; do
  key_file="/etc/ssh/ssh_host_${key_type}_key"
  if [[ ! -f $key_file ]]; then
    ssh-keygen -f $key_file -N '' -t $key_type
  else
    rm -f $key_file
    ssh-keygen -f $key_file -N '' -t $key_type
  fi
done

echo "Setting Hostname..."

# Update /etc/hosts
if [[ ! -f /etc/hosts || ! -s /etc/hosts ]]; then
  echo "/etc/hosts does not exist or is empty. Creating it with default content."
  echo "127.0.0.1   localhost" > /etc/hosts
  echo "127.0.1.1   $newHostname" >> /etc/hosts
else
  sed -i "s/$HOSTNAME/$newHostname/g" /etc/hosts
fi

# Change the hostname in /etc/hostname
echo "$newHostname" > /etc/hostname

# Set the system hostname
hostnamectl set-hostname "$newHostname"

echo "Done!"

# Prompt for reboot
read -p "Would you like to reboot the system now? [Y/N]: " confirm
if [[ $confirm =~ ^[yY](es)?$ ]]; then
  reboot
fi

exit 0
