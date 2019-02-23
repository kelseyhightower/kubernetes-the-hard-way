# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this chapter, you will provision virtual machines required for running a secure and highly available Kubernetes cluster.


## Networking

The Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) assumes a flat network in which containers and nodes can communicate with each other. In cases where this is not desired [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can limit how groups of containers are allowed to communicate with each other and external network endpoints.

> Setting up network policies is out of scope for this tutorial.

### Virtual Network

In this section, Virtual Network will be setup to host the Kubernetes cluster.

1. Open Virtual Machine Manager, and from menu, go to `Edit` -> `Connection Details`.
2. Go to `Virtual Networks` tab, and click the plus(+) button at the left lower side of the window.
3. Type `kubernetes-nw` in the textbox named `Network Name`, and click `Forward`.
4. Type `10.240.0.0/24` in the textbox named `Network`, type `10.240.0.2` in the textbox named `Start`, type `10.240.0.254` in the textbox named `end`, and click `Forward`.
5. You will be asked whether enabling IPv6 or not. Don't check the checkbox, and click `Forward`.
6. Click the radiobutton named `Forwarding to physical network`, type `kubernetes-nw.com` in the textbox named `DNS Domain Name`, and click `Finish`.


## Virtual Machines

The virtual machines in this lab will be provisioned using [Ubuntu Server](https://www.ubuntu.com/server) [16.04](https://wiki.ubuntu.com/XenialXerus/ReleaseNotes). Each virtual machines will be provisioned with a fixed private IP address to simplify the Kubernetes bootstrapping process.

Note that this tutorial assumes that all virtual machines has a same user.

The following virtual machines will be setup in this chapter:

| Name         | vCPU | Ram (MB) | Hostname     | IP Address  |
|--------------|------|----------|--------------|-------------|
| lb-1         | 1    | 256      | lb-1         | 10.240.0.10 |
| controller-1 | 1    | 512      | controller-1 | 10.240.0.11 |
| controller-2 | 1    | 512      | controller-2 | 10.240.0.12 |
| controller-3 | 1    | 512      | controller-3 | 10.240.0.13 |
| worker-1     | 1    | 1024     | worker-1     | 10.240.0.21 |
| worker-2     | 1    | 1024     | worker-2     | 10.240.0.22 |
| worker-3     | 1    | 1024     | worker-3     | 10.240.0.23 |
| client-1     | 1    | 256      | client-1     | 10.240.0.99 |


### Base Image

As installing OS to each virtual machine manually is time-consuming, using a base image where OS is already installed is very handy.

In this chapter, `ubuntu-xenial.qcow2` is assumed to be the base image.


### Kubernetes Controllers

Create three virtual instances which will host the Kubernetes control plane:

1. Open a terminal, or login to the KVM host, and move to the directory where the base image exists (maybe `/var/lib/libvirt/images`?).
2. Create images for Kubernetes controllers backed by the base image:

```
# qemu-img create -f qcow2 -b ubuntu-xenial.qcow2 ubuntu-xenial-controller-1.qcow2
# qemu-img create -f qcow2 -b ubuntu-xenial.qcow2 ubuntu-xenial-controller-2.qcow2
# qemu-img create -f qcow2 -b ubuntu-xenial.qcow2 ubuntu-xenial-controller-3.qcow2
```

(Using each image created above, repeat from 3. to 7..)

3. Open Virtual Machine Manager, and click the icon named `Create a new virtual machine`.
4. Check the radiobutton named `Importing existing disk image`, and click `Forward`.
5. Click `Browse`, click the n-th controller image, click `Choose Volume`, choose the operating system (`Ubuntu 16.04` in this case), and click `Forward`.
6. Type `512` in the textbox named `Memory`, and click Forward.
7. Type `controller-n`(`n` should be `1`, `2`, or `3`), click `Network selection`, select the network `kubernetes-nw`, and click `Finish`.


### Kubernetes Workers

Each worker instance requires a pod subnet allocation from the Kubernetes cluster CIDR range. The pod subnet allocation will be used to configure container networking in a later chapter.

> The Kubernetes cluster CIDR range is defined by the Controller Manager's `--cluster-cidr` flag. In this tutorial the cluster CIDR range will be set to `10.200.0.0/16`, which supports 254 subnets.

Create three virtual machines which will host the Kubernetes worker nodes:

1. Open a terminal, or login to the linux server, and move to the directory where the base image exists (maybe `/var/lib/libvirt/images`?).
2. Create images for Kubernetes controllers backed by the base image:

```
# qemu-img create -f qcow2 -b ubuntu-xenial.qcow2 ubuntu-xenial-worker-1.qcow2
# qemu-img create -f qcow2 -b ubuntu-xenial.qcow2 ubuntu-xenial-worker-2.qcow2
# qemu-img create -f qcow2 -b ubuntu-xenial.qcow2 ubuntu-xenial-worker-3.qcow2
```

(Using each image created above, repeat from 3. to 7..)

3. Open Virtual Machine Manager, and click the icon named `Create a new virtual machine`.
4. Check the radiobutton named `Importing existing disk image`, and click `Forward`.
5. Click `Browse`, click the n-th controller image, click `Choose Volume`, choose the operating system (`Ubuntu 16.04` in this case), and click `Forward`.
6. Type `1024` in the textbox named `Memory`, and click `Forward`.
7. Type `worker-n`(`n` should be `1`, `2`, or `3`), click `Network selection`, select the network `kubernetes-nw`, and click `Finish`.


### Load Balancer for Kubernetes API Server


1. Open a terminal, or login to the KVM host, and move to the directory where the base image exists (maybe `/var/lib/libvirt/images`?).
2. Create images for Kubernetes controllers backed by the base image:

```
# qemu-img create -f qcow2 -b ubuntu-xenial.qcow2 ubuntu-xenial-lb-1.qcow2
```

3. Open Virtual Machine Manager, and click the icon named `Create a new virtual machine`.
4. Check the radiobutton named `Importing existing disk image`, and click `Forward`.
5. Click `Browse`, click the load balancer's image, click `Choose Volume`, choose the operating system (`Ubuntu 16.04` in this case), and click `Forward`.
6. Type `256` in the textbox named `Memory`, and click `Forward`.
7. Type `lb-1`, click `Network selection`, select the network `kubernetes-nw`, and click `Finish`.


### Client for Kubernetes

Instead of Cloud Shell in GCP, create a virtual machine that will be used as a client for Kubernetes.


1. Open a terminal, or login to the linux server, and move to the directory where the base image exists (maybe `/var/lib/libvirt/images`?).
2. Create images for Kubernetes controllers backed by the base image:

```
# qemu-img create -f qcow2 -b ubuntu-xenial.qcow2 ubuntu-xenial-client-1.qcow2
```
3. Open Virtual Machine Manager, and click the icon named `Create a new virtual machine`.
4. Check the radiobutton named `Importing existing disk image`, and click `Forward`.
5. Click `Browse`, click the client's image, click `Choose Volume`, choose the operating system (`Ubuntu 16.04` in this case), and click `Forward`.
6. Type `512` in the textbox named `Memory`, and click `Forward`.
7. Type `client-1`, click `Network selection`, select the network `kubernetes-nw`, and click `Finish`.


## Configuring Virtual Machines


### Setup The Hostname and The IP Address of each Virtual Machine

As described above, the IP address of each virtual machine should be fixed.

Referring to the environment information described above, Set the hostname and the IP Address to each virtual machine.

1. Through SSH or Graphic Console in Virtual Machine Manager, login to the virtual machine.
2. Set the hostname:

```
$ sudo hostnamectl set-hostname <Hostname>
```

3. Edit configuration of network interfaces:

```
$ sudo vi /etc/network/interfaces
$ cat /etc/network/interfaces
```

`interfaces` must look like this:

```
master@lb-0:~$ cat /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto ens3                      # The interface for kubernetes-nw
iface ens3 inet static         # static is set.
address 10.240.0.10            # IP Address of the virtual machine
netmask 255.255.255.0          # netmask of kubernetes-nw
gateway 10.240.0.1             # gateway of kubernetes-nw
dns-nameservers 10.240.0.1     # nameserver of kubernetes-nw
master@lb-0:~$
```

4. Reboot.

```
$ sudo reboot
```


### Configuring SSH Access

SSH will be used to configure the controller and worker nodes.

1. In `client-1`, generate a SSH key.

```
$ ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/<your home directory>/.ssh/id_rsa): /<your home directory>/.ssh/id_rsa-k8s
Enter passphrase (empty for no passphrase):  <Enter with no passphrase>
Enter same passphrase again:  <Enter with no passphrase>
Your identification has been saved in /<your home directory>/.ssh/id_rsa-k8s.
Your public key has been saved in /<your home directory>/.ssh/id_rsa-k8s.pub.
The key fingerprint is:
SHA256:LYoMGbeATYBBdGB5fdPXKbbSDrpSU8WJKjbzsrb3nY8 empty0x7@jb-x260
The key's randomart image is:
+---[RSA 2048]----+
|*B+..   . o o .  |
|o=.. . o o B o   |
|. = . . o = o    |
|   = * . = o     |
|  o o = S =      |
|   o o * . .     |
|    o = o        |
|     + o  . o    |
|    ..+ .. E..   |
+----[SHA256]-----+
$ ll .ssh
total 16
-rw------- 1 <your username> users 1823 Feb 14 21:41 id_rsa-k8s
-rw-r--r-- 1 <your username> users  398 Feb 14 21:41 id_rsa-k8s.pub
-rw-r--r-- 1 <your username> users 2995 Feb  5 00:56 known_hosts
$
```

2. Create a text file containing IP addresses of virtual machines.

```
$ cat << EOF > target_hosts
10.240.0.10
10.240.0.11
10.240.0.12
10.240.0.13
10.240.0.21
10.240.0.22
10.240.0.23
EOF
```

3. Distribute the key to the virtual machines.

```
$ for target in `cat target_hosts`; do ssh-copy-id -i ~/.ssh/id_rsa-k8s.pub <your username>@$target; done
```

You will be asked to enter password of the user(ID) of each virtual machine.

4. Verify it.

```
$ for target in `cat target_hosts`; do ssh -i ~/.ssh/id_rsa-k8s <your username>@$target uname -n; done
```


### Modifying `hosts`

1. In `client-1`, create a text file listing IP addresses and hostnames.

```
$ cat << EOF > new_hosts
10.240.0.10  lb-1
10.240.0.11  controller-1
10.240.0.12  controller-2
10.240.0.13  controller-3
10.240.0.21  worker-1
10.240.0.22  worker-2
10.240.0.23  worker-3
10.240.0.99  client-1
EOF
```

2. Add new hosts to `client-1`.

```
$ sudo su -c 'cat $(realpath new_hosts) >> /etc/hosts'
```

3. Distribute `new_hosts` to the other virtual machines.

```
$ for target in `cat target_hosts`; \
do scp -i ~/.ssh/id_rsa-k8s new_hosts ${USER}@${target}:~/; \
done
```

4. Login to each virtual machines to which `new_hosts` is sent to, add `new_hosts` to `/etc/hosts`.

```
$ for target in $(cat target_hosts); do ssh -t -i ~/.ssh/id_rsa-k8s ${USER}@${target} "sudo su -c 'cat /home/${USER}/new_hosts >> /etc/hosts'"; done
```

You will be asked to enter password of the user(ID) of each virtual machine.


Next: [Installing the Client Tools](docs/03-client-tools.md)
