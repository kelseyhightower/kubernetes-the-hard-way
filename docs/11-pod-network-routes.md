# Provisioning Pod Network Routes

Pods scheduled to a node receive an IP address from the node's Pod CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing network [routes](https://cloud.google.com/compute/docs/vpc/routes).

In this lab you will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address.

> There are [other ways](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) to implement the Kubernetes networking model.

## The Routing Table

In this section you will gather the information required to create routes in the `kubernetes-the-hard-way` VPC network.

Create the Azure route table

```
az network route-table create --resource-group kubernetes-the-hard-way --name kubernetes-the-hard-way-rt
```

## Routes

Create network routes for each worker instance:

```
for i in 0 1 2; do
  az network route-table route create \
    --resource-group kubernetes-the-hard-way \
    --name kubernetes-the-hard-way-route-10-200-${i}-0-24 \
    --route-table-name kubernetes-the-hard-way-rt \
    --next-hop-type VirtualAppliance \
    --next-hop-ip-address 10.240.0.2${i} \
    --address-prefix 10.200.${i}.0/24
done
```

List the routes in the `kubernetes-the-hard-way` VPC network:

```
az network route-table route list --resource-group kubernetes-the-hard-way --route-table-name kubernetes-the-hard-way-rt -o table
```

> output

```
AddressPrefix    Name                                         NextHopIpAddress    NextHopType       ProvisioningState    ResourceGroup
---------------  -------------------------------------------  ------------------  ----------------  -------------------  -----------------------
10.200.0.0/24    kubernetes-the-hard-way-route-10-200-0-0-24  10.240.0.20         VirtualAppliance  Succeeded            kubernetes-the-hard-way
10.200.1.0/24    kubernetes-the-hard-way-route-10-200-1-0-24  10.240.0.21         VirtualAppliance  Succeeded            kubernetes-the-hard-way
10.200.2.0/24    kubernetes-the-hard-way-route-10-200-2-0-24  10.240.0.22         VirtualAppliance  Succeeded            kubernetes-the-hard-way
```

Next: [Deploying the DNS Cluster Add-on](12-dns-addon.md)
