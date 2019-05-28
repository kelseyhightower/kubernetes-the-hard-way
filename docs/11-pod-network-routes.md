# Provisioning Pod Network Routes

Pods scheduled to a node receive an IP address from the node's Pod CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing network [routes](https://cloud.google.com/compute/docs/vpc/routes).

In this lab you will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address.

> There are [other ways](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) to implement the Kubernetes networking model.

## The Routing Table

In this section you will gather the information required to create routes in the `kubernetes-the-hard-way` VPC network.

Create the Azure route table

```
az network route-table create --group kubernetes-the-hard-way --name kubernetes-the-hard-way-rt
```

## Routes

Create network routes for each worker instance:

```
for i in 0 1 2; do
  az network route-table route create \
    --resource-group kubernetes-the-hard-way \
    --name kubernetes-the-hard-way-route-10-200-${i}-0-24 \
    --route-table-name kubernetes-the-hard-way-rt \
    --next-hop-type VnetLocal
    --next-hop-ip-address 10.240.0.2${i}
done
```

List the routes in the `kubernetes-the-hard-way` VPC network:

```
az network route-table route list --resource-group kubernetes-the-hard-way --route-table-name kubernetes-the-hard-way-rt
```

> output

```
NAME                            NETWORK                  DEST_RANGE     NEXT_HOP                  PRIORITY
default-route-081879136902de56  kubernetes-the-hard-way  10.240.0.0/24  kubernetes-the-hard-way   1000
default-route-55199a5aa126d7aa  kubernetes-the-hard-way  0.0.0.0/0      default-internet-gateway  1000
kubernetes-route-10-200-0-0-24  kubernetes-the-hard-way  10.200.0.0/24  10.240.0.20               1000
kubernetes-route-10-200-1-0-24  kubernetes-the-hard-way  10.200.1.0/24  10.240.0.21               1000
kubernetes-route-10-200-2-0-24  kubernetes-the-hard-way  10.200.2.0/24  10.240.0.22               1000
```

Next: [Deploying the DNS Cluster Add-on](12-dns-addon.md)
