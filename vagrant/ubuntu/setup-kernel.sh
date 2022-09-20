#!/bin/bash
#
# Sets up the kernel with the requirements for running Kubernetes
# Requires a reboot, which is carried out by the vagrant provisioner.
set -ex

# Disable cgroups v2 (kernel command line parameter)
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="systemd.unified_cgroup_hierarchy=0 ipv6.disable=1 /' /etc/default/grub
update-grub

# Add br_netfilter kernel module
echo "br_netfilter" >> /etc/modules

# Set network tunables
cat <<EOF >> /etc/sysctl.d/10-kubernetes.conf
net.bridge.bridge-nf-call-iptables=1
net.ipv4.ip_forward=1
EOF

