# Provisioning Pod Network Routes

Pods scheduled to a node receive an IP address from the node's Pod CIDR range.
At this point pods can not communicate with other pods running on different
nodes due to missing network [routes].

In this lab you will create a route for each worker node that maps the node's
Pod CIDR range to the node's internal IP address.

> There are [other ways] to implement the Kubernetes networking model.

## The Routing Table

In this section you will gather the information required to create routes in
the `kubernetes-the-hard-way` VPC network.

Print the internal IP address and Pod CIDR range for each worker instance:

```bash
{
  NODE_0_IP=$(grep node01 machines.txt | cut -d " " -f 1)
  NODE_0_SUBNET=$(grep node01 machines.txt | cut -d " " -f 4)
  NODE_1_IP=$(grep node02 machines.txt | cut -d " " -f 1)
  NODE_1_SUBNET=$(grep node02 machines.txt | cut -d " " -f 4)
}
```

```bash
ssh vagrant@controlplane <<EOF
  sudo ip route add ${NODE_0_SUBNET} via ${NODE_0_IP}
  sudo ip route add ${NODE_1_SUBNET} via ${NODE_1_IP}
EOF
```

```bash
ssh vagrant@node01 <<EOF
  sudo ip route add ${NODE_1_SUBNET} via ${NODE_1_IP}
EOF
```

```bash
ssh vagrant@node02 <<EOF
  sudo ip route add ${NODE_0_SUBNET} via ${NODE_0_IP}
EOF
```

## Verification 

```bash
ssh vagrant@controlplane ip route
```

```text
default via XXX.XXX.XXX.XXX dev ens160 
10.200.0.0/24 via XXX.XXX.XXX.XXX dev ens160 
10.200.1.0/24 via XXX.XXX.XXX.XXX dev ens160 
XXX.XXX.XXX.0/24 dev ens160 proto kernel scope link src XXX.XXX.XXX.XXX 
```

```bash
ssh vagrant@node01 ip route
```

```text
default via XXX.XXX.XXX.XXX dev ens160 
10.200.1.0/24 via XXX.XXX.XXX.XXX dev ens160 
XXX.XXX.XXX.0/24 dev ens160 proto kernel scope link src XXX.XXX.XXX.XXX 
```

```bash
ssh vagrant@node02 ip route
```

```text
default via XXX.XXX.XXX.XXX dev ens160 
10.200.0.0/24 via XXX.XXX.XXX.XXX dev ens160 
XXX.XXX.XXX.0/24 dev ens160 proto kernel scope link src XXX.XXX.XXX.XXX 
```

Next: [Smoke Test](12-smoke-test.md)

---

[routes]: https://cloud.google.com/compute/docs/vpc/routes
[other ways]: https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this