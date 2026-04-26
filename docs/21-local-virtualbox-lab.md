# Local VirtualBox Lab

This lab runs the same Kubernetes The Hard Way architecture on VirtualBox. It is the most portable local option for Windows, Ubuntu, Fedora, and macOS.

The VMs are:

```text
jumpbox  192.168.56.10
server   192.168.56.11
node-0   192.168.56.12
node-1   192.168.56.13
```

The architecture is the same as the libvirt lab:

```text
jumpbox -> administration host
server  -> kube-apiserver, controller-manager, scheduler, etcd
node-0  -> kubelet, kube-proxy, containerd, CNI
node-1  -> kubelet, kube-proxy, containerd, CNI
```

## Why Vagrant

VirtualBox works on Windows and Ubuntu, but creating four VMs by hand is slow and easy to misconfigure. Vagrant gives us one repeatable `Vagrantfile` while still creating real VMs.

You still practice the Kubernetes architecture manually. Vagrant only creates machines, private IPs, hostnames, and SSH access.

## Install Tools

### Windows

Install:

- VirtualBox
- Vagrant
- Git for Windows, or use WSL with Git

After installing, open PowerShell and check:

```powershell
vagrant --version
VBoxManage --version
ssh -V
```

### Ubuntu

Install VirtualBox and Vagrant:

```bash
sudo apt-get update
sudo apt-get install -y virtualbox vagrant openssh-client git
```

Check:

```bash
vagrant --version
VBoxManage --version
ssh -V
```

## Start The VMs

From this repository:

```bash
cd local/virtualbox
vagrant up
```

On Windows PowerShell:

```powershell
cd local\virtualbox
vagrant up
```

The first run downloads the Debian 12 Vagrant box and creates four VMs. This can take a while.

Check state:

```bash
vagrant status
```

## SSH Access

Connect to the jumpbox:

```bash
vagrant ssh jumpbox
```

Become root:

```bash
sudo -i
```

You can also SSH directly from the host after Vagrant has created the machines:

```bash
ssh root@192.168.56.10
```

Vagrant copies its generated SSH key to `root`, and the provisioning script enables key-based root SSH.

## Prepare The Jumpbox

Inside the jumpbox as `root`, install Git and clone your fork:

```bash
apt-get update
apt-get -y install git

git clone --depth 1 \
  https://github.com/KhuramMurad/kubernetes-the-hard-way.git

cd kubernetes-the-hard-way
```

Create `machines.txt`:

```bash
cat > machines.txt <<'EOF'
192.168.56.11 server.kubernetes.local server
192.168.56.12 node-0.kubernetes.local node-0 10.200.0.0/24
192.168.56.13 node-1.kubernetes.local node-1 10.200.1.0/24
EOF
```

Now continue with the normal labs:

```text
docs/02-jumpbox.md
docs/03-compute-resources.md
...
```

You can skip the VM creation part of `docs/01-prerequisites.md` because Vagrant already created the machines.

## Host Convenience File

From the repo on your host, generate the matching machine database:

```bash
scripts/local-virtualbox-machines.sh
```

To write it into the repo:

```bash
scripts/local-virtualbox-machines.sh > machines.txt
```

Copy it to the jumpbox if needed:

```bash
scp machines.txt root@192.168.56.10:~/kubernetes-the-hard-way/
```

## Stop, Start, And Reset

Stop the VMs:

```bash
vagrant halt
```

Start them again:

```bash
vagrant up
```

Destroy and rebuild:

```bash
vagrant destroy -f
vagrant up
```

## Practice Loop

Use this lab when you want portability or when you are helping someone on Windows or Ubuntu.

Practice in this order:

1. Build the cluster from the jumpbox.
2. Confirm all hostnames resolve.
3. Generate certificates and kubeconfigs.
4. Bootstrap etcd and the control plane.
5. Bootstrap both workers.
6. Add Pod routes.
7. Add DNS and run the smoke tests.
8. Break one node and recover it.

Next: [Architecture](00-architecture.md)
