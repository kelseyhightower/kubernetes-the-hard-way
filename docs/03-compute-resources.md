# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this chapter, you will provision virtual machines required for running a secure and highly available Kubernetes cluster.


## Networking

The Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) assumes a flat network in which containers and nodes can communicate with each other. In cases where this is not desired [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can limit how groups of containers are allowed to communicate with each other and external network endpoints.

> Setting up network policies is out of scope for this tutorial.

### Virtual Network

In this section Virtual Network will be setup to host the Kubernetes cluster.

1. Open Virtual Machine Manager, and from menu, go to Edit -> Connection Details.
2. Go to Virtual Networks tab, and click the plus(+) button at the left lower side of the window.
3. Type `kubernetes-nw` in the textbox named `Network Name`, and click Forward.
4. Type `10.240.0.0/24` in the textbox named `Network`, type `10.240.0.2` in the textbox named `Start`, type `10.240.0.254` in the textbox named `end`, and click Forward.
5. You will be asked whether enabling IPv6 or not. Don't check the checkbox, and click Forward.
6. Click the radiobutton named `Forwarding to physical network`, type `kubernetes-nw.com` in the textbox named `DNS Domain Name`, and click Finish.
7. Click the network created above, and take a note of the value of Device. This value will be needed when setting routing.


## Virtual Machines

The virtual machines in this lab will be provisioned using [Ubuntu Server](https://www.ubuntu.com/server) 16.04. Each virtual machines will be provisioned with a fixed private IP address to simplify the Kubernetes bootstrapping process.

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

In this tutorial, `ubuntu-xenial.qcow2` is assumed to be the base image.


### Kubernetes Controllers

Create three virtual instances which will host the Kubernetes control plane:

1. Open a terminal, or login to the linux server, and move to the directory where the base image exists (maybe `/var/lib/libvirt/images`?).
2. Create images for Kubernetes controllers backed by the base image:

```
# qemu-img create -f qcow2 ubuntu-xenial.qcow -b ubuntu-xenial-controller-1.qcow2
# qemu-img create -f qcow2 ubuntu-xenial.qcow -b ubuntu-xenial-controller-2.qcow2
# qemu-img create -f qcow2 ubuntu-xenial.qcow -b ubuntu-xenial-controller-3.qcow2
```

(Using each image created above, repeat from 3. to 7..)

3. Open Virtual Machine Manager, and click the icon named 'Create a new virtual machine'.
4. Check the radiobutton named `Importing existing disk image`, and click Forward
5. Click Browse, click the n-th controller image, click Choose Volume, choose the operating system (`Ubuntu 16.04` in this case), and click Forward.
6. Type `512` in the textbox named `Memory`, and click Forward.
7. Type `controller-n`, click Network selection, select the network `kubernetes-nw`, and click Finish.


(Todo: Setup Network Interface)


### Kubernetes Workers

Each worker instance requires a pod subnet allocation from the Kubernetes cluster CIDR range. The pod subnet allocation will be used to configure container networking in a later exercise. The `pod-cidr` instance metadata will be used to expose pod subnet allocations to compute instances at runtime.

> The Kubernetes cluster CIDR range is defined by the Controller Manager's `--cluster-cidr` flag. In this tutorial the cluster CIDR range will be set to `10.200.0.0/16`, which supports 254 subnets.

Create three virtual machines which will host the Kubernetes worker nodes:

1. Open a terminal, or login to the linux server, and move to the directory where the base image exists (maybe `/var/lib/libvirt/images`?).
2. Create images for Kubernetes controllers backed by the base image:

```
# qemu-img create -f qcow2 ubuntu-xenial.qcow -b ubuntu-xenial-worker-1.qcow2
# qemu-img create -f qcow2 ubuntu-xenial.qcow -b ubuntu-xenial-worker-2.qcow2
# qemu-img create -f qcow2 ubuntu-xenial.qcow -b ubuntu-xenial-worker-3.qcow2
```

(Using each image created above, repeat from 3. to 7..)

3. Open Virtual Machine Manager, and click the icon named 'Create a new virtual machine'.
4. Check the radiobutton named `Importing existing disk image`, and click Forward
5. Click Browse, click the n-th controller image, click Choose Volume, choose the operating system (`Ubuntu 16.04` in this case), and click Forward.
6. Type `512` in the textbox named `Memory`, and click Forward.
7. Type `worker-n`, click Network selection, select the network `kubernetes-nw`, and click Finish.

(Todo: Setup Network Interface)


### Load Balancer for Kubernetes API Server

Kuberentes API Server...


1. Open a terminal, or login to the linux server, and move to the directory where the base image exists (maybe `/var/lib/libvirt/images`?).
2. Create images for Kubernetes controllers backed by the base image:

```
# qemu-img create -f qcow2 ubuntu-xenial.qcow -b ubuntu-xenial-lb-1.qcow2
```

3. Open Virtual Machine Manager, and click the icon named 'Create a new virtual machine'.
4. Check the radiobutton named `Importing existing disk image`, and click Forward
5. Click Browse, click the n-th controller image, click Choose Volume, choose the operating system (`Ubuntu 16.04` in this case), and click Forward.
6. Type `512` in the textbox named `Memory`, and click Forward.
7. Type `lb-1`, click Network selection, select the network `kubernetes-nw`, and click Finish.


### Client for Kubernetes

Create a virtual machine, instead of Cloud Shell in GCP, that will be used as a client for Kubernetes.


1. Open a terminal, or login to the linux server, and move to the directory where the base image exists (maybe `/var/lib/libvirt/images`?).
2. Create images for Kubernetes controllers backed by the base image:

```
# qemu-img create -f qcow2 ubuntu-xenial.qcow -b ubuntu-xenial-client-1.qcow2
```
3. Open Virtual Machine Manager, and click the icon named 'Create a new virtual machine'.
4. Check the radiobutton named `Importing existing disk image`, and click Forward
5. Click Browse, click the n-th controller image, click Choose Volume, choose the operating system (`Ubuntu 16.04` in this case), and click Forward.
6. Type `512` in the textbox named `Memory`, and click Forward.
7. Type `client-1`, click Network selection, select the network `kubernetes-nw`, and click Finish.


## Configure Virtual Machines


### Setup The Hostname and The IP Address of each Virtual Machine

As described above, the IP address of each virtual machine should be fixed.

Referring to the environment information described above, Set the IP Address to each virtual machine.

1. Login to the virtual machine.
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


### Modify `hosts`

Though resolving hostnames is unnecessary, ...

1. In the host PC, create a text file listing IP addresses and hostnames:

```
$ cat << EOF > new_hosts
10.240.0.11  controller-1
10.240.0.12  controller-2
10.240.0.13  controller-3
10.240.0.10  lb-1
10.240.0.21  worker-1
10.240.0.22  worker-2
10.240.0.23  worker-3
10.240.0.99  client-1
EOF
```

## Configuring SSH Access

SSH will be used to configure the controller and worker instances.

1. In the host PC, generate a SSH key.

```
$ ssh-keygen

(...)

```

2. Create a text file containing IP addresses of virtual machines.

```
$ cat << EOF > target_hosts.txt
10.240.0.10
10.240.0.11
10.240.0.12
10.240.0.13
10.240.0.21
10.240.0.22
10.240.0.23
10.240.0.99
EOF
```

3. Distribute the key to the virtual machines.

```
$ for target in `cat target_hosts`; do ssh-copy-id -i ~/.ssh/id_rsa-k8s.pub <ID>@$target; done
```

You will be asked to enter password of the user(ID).

4. Verify ...

```
$ do ssh -i ~/.ssh/id_rsa-k8s <ID>@$target uname -n; done
```

Next: [Provisioning a CA and Generating TLS Certificates](04-certificate-authority.md)
