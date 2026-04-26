# Local libvirt Lab

This lab maps the tutorial architecture onto one Fedora workstation using KVM/libvirt.

Your local machine acts as the physical host. The Kubernetes lab still runs inside four Debian 12 virtual machines:

```text
Fedora host
  |
  +-- khw-jumpbox  192.168.122.210
  +-- khw-server   192.168.122.211
  +-- khw-node-0   192.168.122.212
  +-- khw-node-1   192.168.122.213
```

Inside the lab, the architecture is unchanged:

```text
jumpbox -> administration host
server  -> kube-apiserver, controller-manager, scheduler, etcd
node-0  -> kubelet, kube-proxy, containerd, CNI
node-1  -> kubelet, kube-proxy, containerd, CNI
```

## Why This Setup

This gives you the same mental model as a small bare-metal or cloud lab:

- every Kubernetes component has a real Linux systemd service
- SSH, hostnames, certificates, kubeconfigs, and routes behave like the guide says
- you can break and repair individual nodes
- etcd backup, kubelet debugging, CNI routing, and CoreDNS all feel real

It is slower than `kind`, but better for learning the architecture.

## Host Requirements

On the Fedora host:

```bash
sudo dnf install -y \
  libvirt \
  virt-install \
  libguestfs-tools \
  qemu-img \
  genisoimage \
  openssh-clients \
  wget
```

Start libvirt:

```bash
sudo systemctl enable --now libvirtd
sudo virsh net-start default
sudo virsh net-autostart default
```

Confirm the default network:

```bash
sudo virsh net-list --all
sudo virsh net-dumpxml default
```

The default network normally uses `192.168.122.0/24`.

## Reserve Lab IPs

Run this section on the Fedora host.

Add DHCP reservations to the default libvirt network:

```bash
sudo virsh net-update default add ip-dhcp-host \
  "<host mac='52:54:00:20:00:10' name='khw-jumpbox' ip='192.168.122.210'/>" \
  --live --config

sudo virsh net-update default add ip-dhcp-host \
  "<host mac='52:54:00:20:00:11' name='khw-server' ip='192.168.122.211'/>" \
  --live --config

sudo virsh net-update default add ip-dhcp-host \
  "<host mac='52:54:00:20:00:12' name='khw-node-0' ip='192.168.122.212'/>" \
  --live --config

sudo virsh net-update default add ip-dhcp-host \
  "<host mac='52:54:00:20:00:13' name='khw-node-1' ip='192.168.122.213'/>" \
  --live --config
```

If a reservation already exists, remove the old one or choose a different IP before continuing.

## Create A Root SSH Key

Run this section on the Fedora host.

The main tutorial uses root SSH for learning convenience. Use your existing host key:

```bash
test -f ~/.ssh/id_ed25519.pub || ssh-keygen -t ed25519
```

## Download Debian 12 Cloud Image

Run this section on the Fedora host.

```bash
mkdir -p ~/lab-images/kubernetes-the-hard-way
cd ~/lab-images/kubernetes-the-hard-way

wget -nc \
  https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
```

## Create VM Disks

Run this section on the Fedora host.

```bash
cd ~/lab-images/kubernetes-the-hard-way

for vm in khw-jumpbox khw-server khw-node-0 khw-node-1; do
  qemu-img create -f qcow2 \
    -F qcow2 \
    -b debian-12-generic-amd64.qcow2 \
    "${vm}.qcow2" 20G
done
```

## Create A Lab SSH Key

Run this section on the Fedora host.

Create a lab-only key that the jumpbox will use to administer the other machines:

```bash
ssh-keygen -t ed25519 \
  -N "" \
  -f khw-root
```

This key is intentionally scoped to these disposable local VMs. The public key will be trusted by all four machines, and the private key will be copied only into the jumpbox.

## Customize The VM Images

Run this section on the Fedora host.

Inject hostnames, networking, SSH access, and the jumpbox administration key:

```bash
cat > 10-dhcp.network <<'EOF'
[Match]
Name=en* eth*

[Network]
DHCP=yes
EOF

for vm in khw-jumpbox khw-server khw-node-0 khw-node-1; do
  sudo LIBGUESTFS_BACKEND=direct virt-customize -a "${vm}.qcow2" \
    --hostname "${vm}" \
    --install openssh-server \
    --ssh-inject root:file:khw-root.pub \
    --copy-in 10-dhcp.network:/etc/systemd/network/ \
    --root-password password:kubernetes \
    --run-command "mkdir -p /etc/ssh/sshd_config.d" \
    --run-command "printf 'PermitRootLogin prohibit-password\nPubkeyAuthentication yes\nPasswordAuthentication no\n' > /etc/ssh/sshd_config.d/99-kubernetes-the-hard-way.conf" \
    --run-command "ssh-keygen -A" \
    --run-command "systemctl enable systemd-networkd" \
    --run-command "systemctl unmask ssh.service" \
    --run-command "systemctl enable ssh.service"
done

sudo LIBGUESTFS_BACKEND=direct virt-customize -a khw-jumpbox.qcow2 \
  --copy-in khw-root:/root/.ssh/ \
  --run-command "mv /root/.ssh/khw-root /root/.ssh/id_ed25519" \
  --run-command "chown root:root /root/.ssh/id_ed25519" \
  --run-command "chmod 600 /root/.ssh/id_ed25519"
```

`prohibit-password` allows key-based root login while keeping password login disabled.

`LIBGUESTFS_BACKEND=direct` tells libguestfs to customize the image directly instead of creating a temporary libvirt appliance. This avoids the common Fedora error where libvirt tries to read images under `/home` as its `qemu` user and gets `Permission denied`.

The `10-dhcp.network` file makes the imported Debian cloud image request an address from libvirt DHCP. Without cloud-init metadata or an explicit network file, the VM can boot but never receive an IP address.

`openssh-server` is installed explicitly because some minimal Debian cloud images boot successfully but do not have an SSH daemon listening on port `22`. If `ssh root@192.168.122.210` returns `Connection refused`, the VM has networking but `sshd` is not running.

The `khw-root` key makes the jumpbox behave like the administration machine in the main tutorial. Without this, the worker nodes may trust a key from your host workstation, while the jumpbox has no matching private key and gets `Permission denied (publickey)`.

The temporary root password is `kubernetes`. It is only for console recovery with `sudo virsh console <vm-name>` while building the local lab. SSH password login remains disabled by the drop-in config.

## Move Disks Into libvirt Storage

Run this section on the Fedora host.

System libvirt runs virtual machines as its own `qemu` user. On Fedora, that user normally cannot read files inside your home directory. Move the prepared images into libvirt's image directory before creating the VMs:

```bash
sudo mkdir -p /var/lib/libvirt/images/kubernetes-the-hard-way

sudo cp \
  ~/lab-images/kubernetes-the-hard-way/debian-12-generic-amd64.qcow2 \
  ~/lab-images/kubernetes-the-hard-way/khw-*.qcow2 \
  /var/lib/libvirt/images/kubernetes-the-hard-way/

sudo chown qemu:qemu /var/lib/libvirt/images/kubernetes-the-hard-way/*.qcow2
sudo chmod 0640 /var/lib/libvirt/images/kubernetes-the-hard-way/*.qcow2
sudo restorecon -Rv /var/lib/libvirt/images/kubernetes-the-hard-way
```

Use the libvirt image directory for the remaining VM creation commands:

```bash
cd /var/lib/libvirt/images/kubernetes-the-hard-way
```

## Create The VMs

Run this section on the Fedora host.

```bash
cd /var/lib/libvirt/images/kubernetes-the-hard-way

sudo virt-install \
  --name khw-jumpbox \
  --memory 1024 \
  --vcpus 1 \
  --disk path="${PWD}/khw-jumpbox.qcow2",bus=virtio \
  --os-variant debian12 \
  --import \
  --network network=default,model=virtio,mac=52:54:00:20:00:10 \
  --graphics none \
  --noautoconsole

sudo virt-install \
  --name khw-server \
  --memory 2048 \
  --vcpus 1 \
  --disk path="${PWD}/khw-server.qcow2",bus=virtio \
  --os-variant debian12 \
  --import \
  --network network=default,model=virtio,mac=52:54:00:20:00:11 \
  --graphics none \
  --noautoconsole

sudo virt-install \
  --name khw-node-0 \
  --memory 2048 \
  --vcpus 1 \
  --disk path="${PWD}/khw-node-0.qcow2",bus=virtio \
  --os-variant debian12 \
  --import \
  --network network=default,model=virtio,mac=52:54:00:20:00:12 \
  --graphics none \
  --noautoconsole

sudo virt-install \
  --name khw-node-1 \
  --memory 2048 \
  --vcpus 1 \
  --disk path="${PWD}/khw-node-1.qcow2",bus=virtio \
  --os-variant debian12 \
  --import \
  --network network=default,model=virtio,mac=52:54:00:20:00:13 \
  --graphics none \
  --noautoconsole
```

Check VM state:

```bash
sudo virsh list --all
```

## Connect To The Jumpbox

Run the first command on the Fedora host:

```bash
ssh root@192.168.122.210
```

Run the rest of this section inside `khw-jumpbox` as `root`.

From the jumpbox, clone your fork:

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
192.168.122.211 server.kubernetes.local server
192.168.122.212 node-0.kubernetes.local node-0 10.200.0.0/24
192.168.122.213 node-1.kubernetes.local node-1 10.200.1.0/24
EOF
```

Clean accidental blank lines before using the machine database:

```bash
sed -i '/^[[:space:]]*$/d' machines.txt
```

Verify the jumpbox can reach the other machines:

```bash
while read IP FQDN HOST SUBNET; do
  ssh root@${IP} hostname
done < machines.txt
```

Now continue with:

```text
docs/02-jumpbox.md
docs/03-compute-resources.md
...
```

You can skip the machine provisioning part of `docs/01-prerequisites.md` because the VMs already exist.

## Host Convenience File

Run this section on the Fedora host.

From the repo on your Fedora host, generate a matching inventory:

```bash
scripts/local-libvirt-machines.sh
```

To write it into the repo:

```bash
scripts/local-libvirt-machines.sh > machines.txt
```

Copy it to the jumpbox if needed:

```bash
scp machines.txt root@192.168.122.210:~/kubernetes-the-hard-way/
```

## Repair Jumpbox SSH Access

Run this section only if the jumpbox can SSH into itself but gets `Permission denied (publickey)` when connecting to `server`, `node-0`, or `node-1`.

Generate a key inside `khw-jumpbox`:

```bash
ssh root@192.168.122.210
ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519
cat /root/.ssh/id_ed25519.pub
```

Copy the public key output. Then run the remaining commands on the Fedora host.

Create a temporary public key file:

```bash
cat > /tmp/jumpbox-root.pub <<'EOF'
PASTE_THE_PUBLIC_KEY_FROM_JUMPBOX_HERE
EOF
```

Stop the target VMs:

```bash
for vm in khw-server khw-node-0 khw-node-1; do
  sudo virsh destroy "$vm" || true
done
```

Inject the jumpbox key:

```bash
cd /var/lib/libvirt/images/kubernetes-the-hard-way

for vm in khw-server khw-node-0 khw-node-1; do
  sudo LIBGUESTFS_BACKEND=direct virt-customize -a "${vm}.qcow2" \
    --ssh-inject root:file:/tmp/jumpbox-root.pub
done
```

Start the target VMs:

```bash
for vm in khw-server khw-node-0 khw-node-1; do
  sudo virsh start "$vm"
done
```

Return to `khw-jumpbox` and verify:

```bash
cd ~/kubernetes-the-hard-way
sed -i '/^[[:space:]]*$/d' machines.txt

while read IP FQDN HOST SUBNET; do
  ssh root@${IP} hostname
done < machines.txt
```

## Practice Loop

Use this setup in layers:

1. Build the cluster once by following every command.
2. Rebuild only certificates and kubeconfigs until the identities make sense.
3. Break one worker and recover it using `journalctl`, `crictl`, and `kubectl describe node`.
4. Delete the manual Pod routes and recreate them.
5. Deploy CoreDNS and prove Service DNS works.
6. Take an etcd snapshot, delete a workload, and restore.
7. Repeat the smoke test without looking at the docs.

## Reset

Destroy only the lab VMs:

```bash
for vm in khw-jumpbox khw-server khw-node-0 khw-node-1; do
  sudo virsh destroy "${vm}" || true
  sudo virsh undefine "${vm}" || true
done
```

Remove disks:

```bash
rm -f ~/lab-images/kubernetes-the-hard-way/khw-*.qcow2
```

Keep the base Debian image so rebuilding is fast.

Next: [Architecture](00-architecture.md)
