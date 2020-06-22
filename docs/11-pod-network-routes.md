# Provisioning Pod Network Routes

Pods scheduled to a node receive an IP address from the node's Pod CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing network [routes](https://cloud.google.com/compute/docs/vpc/routes).

In this lab you will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address.

> There are [other ways](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) to implement the Kubernetes networking model.

## The Routing Table

**On each worker node**, add the following routes:

> **WARNING**: don't add the route associated to the POD CIDR for the current node (ex: don't add the 10.200.0.0/24 route if you are on the worker-0 node).

```bash
ip route add 10.200.0.0/24 via 192.168.8.20 # Don't add on worker-0
ip route add 10.200.1.0/24 via 192.168.8.21 # Don't add on worker-1
ip route add 10.200.2.0/24 via 192.168.8.22 # Don't add on worker-2
```

> Don't take care of the `RTNETLINK answers: File exists` message, it appears just when you try to add an existing route, not a real problem.

List the routes in the `kubernetes-the-hard-way` VPC network:

```bash
ip route
```

> Output (example for worker-0):

```bash
default via 192.168.8.1 dev ens18 proto static
10.200.1.0/24 via 192.168.8.21 dev ens18
10.200.2.0/24 via 192.168.8.22 dev ens18
192.168.8.0/24 dev ens18 proto kernel scope link src 192.168.8.21
```

To make it persistent (if reboot), you need to edit your network configuration (depends on your Linux distribution).

Example for **Ubuntu 18.04** and higher:

```bash
vi /etc/netplan/00-installer-config.yaml
```

> Content (example for worker-0, **don't specify the POD CIDR associated with the current node**):

```bash
# This is the network config written by 'subiquity'
network:
  ethernets:
    ens18:
      addresses:
      - 192.168.8.10/24
      gateway4: 192.168.8.1
      nameservers:
        addresses:
        - 9.9.9.9
      routes:
      - to: 10.200.1.0/24
        via: 192.168.8.21
      - to: 10.200.2.0/24
        via: 192.168.8.22
  version: 2
```

Next: [Deploying the DNS Cluster Add-on](12-dns-addon.md)
