# Cleaning Up

In this lab you will delete the resources created during this tutorial.

## Virtual Machines

Stop the 7 VM created for this tutorial:

```bash
sudo shutdown -h now
```

Delete all the VMs via the Proxmox WebUI or the Proxmox CLI (on the hypervisor):

```bash
sudo qm destroy <vmid> --purge
```

## Networking

Delete the private Kubernetes network (`vmbr8`) via the Proxmox WebUI (to avoid fatal misconfiguration).
