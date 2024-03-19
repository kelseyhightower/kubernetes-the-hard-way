#!/usr/bin/env bash

# Set hostfile entries
sudo sed -i "/$(hostname)/d" /etc/hosts
cat /tmp/hostentries | sudo tee -a /etc/hosts &> /dev/null

# Export internal IP of primary NIC as an environment variable
echo "PRIMARY_IP=$(ip route | grep default | awk '{ print $9 }')" | sudo tee -a /etc/environment > /dev/null

# Export architecture as environment variable to download correct versions of software
echo "ARCH=arm64"  | sudo tee -a /etc/environment > /dev/null

# Enable password auth in sshd so we can use ssh-copy-id
# Enable password auth in sshd so we can use ssh-copy-id
sudo sed -i --regexp-extended 's/#?PasswordAuthentication (yes|no)/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i --regexp-extended 's/#?Include \/etc\/ssh\/sshd_config.d\/\*.conf/#Include \/etc\/ssh\/sshd_config.d\/\*.conf/' /etc/ssh/sshd_config
sudo sed -i 's/KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd

if [ "$(hostname)" = "controlplane01" ]
then
    sh -c 'sudo apt update' &> /dev/null
    sh -c 'sudo apt-get install -y sshpass' &> /dev/null
 fi

# Set password for ubuntu user (it's something random by default)
echo 'ubuntu:ubuntu' | sudo chpasswd