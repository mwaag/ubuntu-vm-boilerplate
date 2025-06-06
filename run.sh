#!/bin/bash

source /etc/lsb-release

if [[ "$DISTRIB_ID" -ne "Ubuntu" ]]; then
  echo "No action taken..."
  echo "Are you sure this is an Ubuntu system?"
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "No action taken..."
  echo "This script must be run as root"
  exit 1
fi

read -p "Enter desired hostname: " newHostname

echo "Generating new Machine ID"
rm -f /var/lib/dbus/machine-id
rm -f /etc/machine-id
dbus-uuidgen --ensure=/etc/machine-id
ln -s /etc/machine-id /var/lib/dbus/

echo "Generating SSH server keys"

# Überprüfen und RSA-Schlüssel generieren
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
else
    rm -f /etc/ssh/ssh_host_rsa_key
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi

# Überprüfen und DSA-Schlüssel generieren
if [ ! -f /etc/ssh/ssh_host_dsa_key ]; then
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
else
    rm -f /etc/ssh/ssh_host_dsa_key
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi

# Überprüfen und ECDSA-Schlüssel generieren
if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then
    ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa -b 521
else
    rm -f /etc/ssh/ssh_host_ecdsa_key
    ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa -b 521
fi

echo "Setting Hostname"

# Überprüfen, ob /etc/hosts existiert und ob sie leer ist
if [ ! -f /etc/hosts ] || [ ! -s /etc/hosts ]; then
    echo "/etc/hosts does not exist or is empty. Creating it with default content."
    echo "127.0.0.1   localhost" > /etc/hosts
    echo "127.0.1.1   $newHostname" >> /etc/hosts
else
    # Wenn die Datei existiert und nicht leer ist, den Hostnamen ersetzen
    sed -i "s/$HOSTNAME/$newHostname/g" /etc/hosts
fi

# Hostnamen in /etc/hostname ändern
sed -i "s/$HOSTNAME/$newHostname/g" /etc/hostname

# Hostnamen des Systems setzen
hostnamectl set-hostname $newHostname

echo "Done!"

read -p "Would you like to reboot the system now? [Y/N]: " confirm &&
  [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

reboot
exit 0
