#!/usr/bin/env bash

# Step 2 - Set up Operating System Prerequisites

# Load required kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Persist modules between restarts
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Set required networking parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
