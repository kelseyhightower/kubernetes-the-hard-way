# Vagrant

This directory contains the configuration for the virtual machines we will use for the installation.

A few prerequisites are handled by the VM provisioning steps.

## Kernel Settings

1. Install the `br_netfilter` kernel module that permits kube-proxy to manipulate IP tables rules.
1. Add the two tunables `net.bridge.bridge-nf-call-iptables=1` and `net.ipv4.ip_forward=1` also required for successful pod networking.

## DNS settings

1. Set the default DNS server to be Google, as we know this always works.
1. Set up `/etc/hosts` so that all the VMs can resolve each other

## Other settings

1. Install configs for `vim` and `tmux` on controlplane01
