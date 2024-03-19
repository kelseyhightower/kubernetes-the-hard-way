#!/bin/bash
#
# Set up /etc/hosts so we can resolve all the machines in the VirtualBox network
set -e
IFNAME=$1
THISHOST=$2

# Host will have 3 interfaces: lo, DHCP assigned NAT network and static on VM network
# We want the VM network
PRIMARY_IP="$(ip -4 addr show | grep "inet" | egrep -v '(dynamic|127\.0\.0)' | awk '{print $2}' | cut -d/ -f1)"
NETWORK=$(echo $PRIMARY_IP | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s", $1, $2, $3) }')
#sed -e "s/^.*${HOSTNAME}.*/${PRIMARY_IP} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts

# Export PRIMARY IP as an environment variable
echo "PRIMARY_IP=${PRIMARY_IP}" >> /etc/environment

# Export architecture as environment variable to download correct versions of software
echo "ARCH=amd64"  | sudo tee -a /etc/environment > /dev/null

# remove ubuntu-jammy entry
sed -e '/^.*ubuntu-jammy.*/d' -i /etc/hosts
sed -e "/^.*$2.*/d" -i /etc/hosts

# Update /etc/hosts about other hosts
cat >> /etc/hosts <<EOF
${NETWORK}.11  controlplane01
${NETWORK}.12  controlplane02
${NETWORK}.21  node01
${NETWORK}.22  node02
${NETWORK}.30  loadbalancer
EOF
