# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this lab you will check and eventually adjust the configuration defined in the `01-prerequisites` part.

## Networking

The Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) assumes a flat network in which containers and nodes can communicate with each other. In cases where this is not desired [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can limit how groups of containers are allowed to communicate with each other and external network endpoints.

> Setting up network policies is out of scope for this tutorial.

### Virtual Private Cloud Network

We provisioned this network in the `01-prerequisites` part: `192.168.8.0/24` which can host up to `253` Kubernetes nodes (`254 - 1` for gateway). This is our "VPC-like" network with private IP addresses.

### Pods Network Ranges

Containers/Pods running on each workers need networks to communicate with other ressources. We will use the `10.200.0.0/16` private range to create Pods subnetworks:

* 10.200.0.0/24 : worker-0
* 10.200.1.0/24 : worker-1
* 10.200.2.0/24 : worker-2

### Firewall Rules

All the flows are allowed inside the Kubernetes private network (`vmbr8`). In the `01-prerequisites` part, the `gateway-01` VM firewall has been configured to use NAT and allow the following INPUT protocols (from external): `icmp`, `tcp/22`, `tcp/80`, `tcp/443` and `tcp/6443`.

Check the rules on the `gateway-01` VM (example if `ens18` is the public network interface):

```bash
root@gateway-01:~# iptables -L INPUT -v -n
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
 2062  905K ACCEPT     all  --  lo     *       0.0.0.0/0            0.0.0.0/0
 150K   21M ACCEPT     tcp  --  ens18  *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22
 7259  598K ACCEPT     tcp  --  ens18  *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80
  772 32380 ACCEPT     tcp  --  ens18  *       0.0.0.0/0            0.0.0.0/0            tcp dpt:443
  772 32380 ACCEPT     tcp  --  ens18  *       0.0.0.0/0            0.0.0.0/0            tcp dpt:6443
23318 1673K ACCEPT     icmp --  ens18  *       0.0.0.0/0            0.0.0.0/0
  36M 6163M ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0            state RELATED,ESTABLISHED
 113K 5899K DROP       all  --  ens18  *       0.0.0.0/0            0.0.0.0/0
```

### Kubernetes Public IP Address

A public IP address need to be defined on the public network interface of the `gateway-01` VM (done in the `01-prerequisites` part).

### Verification

On each VM, check the active IP address(es) with the following command:

```bash
ip a
```

> Output (example with controller-0):

```bash
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: ens18: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether e6:27:6e:8c:d6:7b brd ff:ff:ff:ff:ff:ff
    inet 192.168.8.10/24 brd 192.168.8.255 scope global ens18
       valid_lft forever preferred_lft forever
    inet6 fe80::e427:6eff:fe8c:d67b/64 scope link
       valid_lft forever preferred_lft forever
```

From the gateway-01 VM, try to ping all controllers and workers VM:

```bash
for i in 0 1 2; do ping -c1 controller-$i; ping -c1 worker-$i; done
```

> Output (example with controller-0)

```bash
PING controller-0 (192.168.8.10) 56(84) bytes of data.
64 bytes from controller-0 (192.168.8.10): icmp_seq=1 ttl=64 time=0.598 ms

--- controller-0 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.598/0.598/0.598/0.000 ms
PING worker-0 (192.168.8.20) 56(84) bytes of data.
64 bytes from worker-0 (192.168.8.20): icmp_seq=1 ttl=64 time=0.474 ms

--- worker-0 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.474/0.474/0.474/0.000 ms
PING controller-1 (192.168.8.11) 56(84) bytes of data.
64 bytes from controller-1 (192.168.8.11): icmp_seq=1 ttl=64 time=0.546 ms

--- controller-1 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.546/0.546/0.546/0.000 ms
PING worker-1 (192.168.8.21) 56(84) bytes of data.
64 bytes from worker-1 (192.168.8.21): icmp_seq=1 ttl=64 time=1.10 ms

--- worker-1 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.101/1.101/1.101/0.000 ms
PING controller-2 (192.168.8.12) 56(84) bytes of data.
64 bytes from controller-2 (192.168.8.12): icmp_seq=1 ttl=64 time=0.483 ms

--- controller-2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.483/0.483/0.483/0.000 ms
PING worker-2 (192.168.8.22) 56(84) bytes of data.
64 bytes from worker-2 (192.168.8.22): icmp_seq=1 ttl=64 time=0.650 ms

--- worker-2 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.650/0.650/0.650/0.000 ms
```

## Configuring SSH Access

SSH will be used to configure the controller and worker instances.

On the `gateway-01` VM, generate SSH key for your working user:

```bash
ssh-keygen
```

> Output (example for the user nemo):

```bash
Generating public/private rsa key pair.
Enter file in which to save the key (/home/nemo/.ssh/id_rsa):
Created directory '/home/nemo/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/nemo/.ssh/id_rsa.
Your public key has been saved in /home/nemo/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:QIhkUeJWxh9lJRwfpJpkYXiuHjgE7icWVjo8dQzh+2Q nemo@gateway-01
The key's randomart image is:
+---[RSA 2048]----+
| .=BBo+o=++      |
|.oo*+=oo.+ .     |
|o.*..++.. .      |
| X. .oo+         |
|o.+o Eo S        |
| +o.*            |
|. oo o           |
|    .            |
|                 |
+----[SHA256]-----+
```

Print the public key and copy it:

```bash
cat /home/nemo/.ssh/id_rsa.pub
```

> Output (example for the user nemo):

```bash
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZwdkThm90GKiBPcECnxqPfPIy0jz3KAVxS5i1GcfdOMmj947/iYlKrYVqXmPqHOy1vDRJQHD1KpkADSnXREoUJp6RpugR+qei962udVY+Y/eNV2JZRt/dcTlGwqSwKjjE8a5n84fu4zgJcvIIZYG/vJpN3ock189IuSjSeLSBAPU/UQzTDAcNnHEeHDv7Yo2wxGoDziM7sRGQyFLVHKJKtA28+OZT8DKaE4XY78ovmsMJuMDMF+YLKm12/f79xS0AYw0KXb97TAb9PhFMqqOKknN+mvzbccAih6gJEwB646Ju6VlBRBky7c6ZMsDR9l99uQtlXcv8lwiheYE4nJmF nemo@gateway-01
```

On the controllers and workers nodes, create the `/root/.ssh` folder and create the file `/root/.ssh/authorized_keys` to paste the previously copied public key:

```bash
mkdir -p /root/.ssh
vi /root/.ssh/authorized_keys
```

From the `gateway-01`, check if you can connect to the `root` account of all controllers and workers (example for controller-0):

```bash
ssh root@controller-0
```

> Output:

```bash
Welcome to Ubuntu 18.04.4 LTS (GNU/Linux 4.15.0-101-generic x86_64)

...

Last login: Sat Jun 20 11:03:45 2020 from 192.168.8.1
root@controller-0:~#
```

Now, you can logout:

```bash
exit
```

> Output:

```bash
logout
Connection to controller-0 closed.
nemo@gateway-01:~$
```

Next: [Provisioning a CA and Generating TLS Certificates](04-certificate-authority.md)
