#!/bin/bash
#
# Set up /etc/hosts so we can resolve all the machines in the VirtualBox network
set -ex
IFNAME=$1
THISHOST=$2
ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
NETWORK=$(echo $ADDRESS | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s", $1, $2, $3) }')
sed -e "s/^.*${HOSTNAME}.*/${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts

# remove ubuntu-jammy entry
sed -e '/^.*ubuntu-jammy.*/d' -i /etc/hosts
sed -e "/^.*$2.*/d" -i /etc/hosts

# Update /etc/hosts about other hosts
cat >> /etc/hosts <<EOF
${NETWORK}.11  master-1
${NETWORK}.12  master-2
${NETWORK}.21  worker-1
${NETWORK}.22  worker-2
${NETWORK}.30  loadbalancer
EOF
