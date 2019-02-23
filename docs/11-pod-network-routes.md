# Adding Pod Network Routes

Pods scheduled to a node receive an IP address from the node's Pod CIDR range. At this point pods cannot communicate with other pods running on different nodes due to missing network routes.

In this chapter, you will create routes for each worker node that maps the node's Pod CIDR range to the node's IP address.

> There are [other ways](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) to implement the Kubernetes networking model.

**The instructions in this chapter should be done in the host, not in the virtual machines.**


## Routes

Get the bridge name of `kubernetes-nw`.

```
$ KUBERNETES_BRIDGE=$(sudo virsh net-info kubernetes-nw | grep Bridge | awk '{ print $2}')
```

Create network routes for each worker instance:

```
$ for i in 1 2 3; do
  sudo ip route add  10.200.${i}.0/24 via 10.240.0.2${i} dev ${KUBERNETES_BRIDGE}
done
```

List the routes in the host:

```
$ ip route
```

> output

```
default via 172.16.0.1 dev wlp4s0 proto dhcp metric 600
10.200.1.0/24 via 10.240.0.21 dev virbr1
10.200.2.0/24 via 10.240.0.22 dev virbr1
10.200.3.0/24 via 10.240.0.23 dev virbr1
10.240.0.0/24 dev virbr1 proto kernel scope link src 10.240.0.1

(...)

```

Next: [Deploying the DNS Cluster Add-on](12-dns-addon.md)
