# Provisioning Pod Network Routes

Pods scheduled to a node receive an IP address from the node's Pod CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing network [routes](https://cloud.google.com/compute/docs/vpc/routes).

In this lab you will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address.

> There are [other ways](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) to implement the Kubernetes networking model.

## The Routing Table

In this section you will gather the information required to create routes in the `kubernetes-the-hard-way` VCN.

Print the internal IP address and Pod CIDR range for each worker instance:

```
for instance in worker-0 worker-1 worker-2; do
  NODE_ID=$(oci compute instance list --lifecycle-state RUNNING --display-name $instance | jq -r .data[0].id)
  PRIVATE_IP=$(oci compute instance list-vnics --instance-id $NODE_ID | jq -r '.data[0]["private-ip"]')
  POD_CIDR=$(oci compute instance list --lifecycle-state RUNNING --display-name $instance | jq -r '.data[0].metadata["pod-cidr"]')
  echo "$PRIVATE_IP $POD_CIDR"
done
```

> output

```
10.240.0.20 10.200.0.0/24
10.240.0.21 10.200.1.0/24
10.240.0.22 10.200.2.0/24
```

## Routes

Here, we'll update our Route Table to include, for each worker node, a route from the worker node's pod CIDR to the worker node's private address:

```
{
  ROUTE_TABLE_ID=$(oci network route-table list --display-name kubernetes-the-hard-way --vcn-id $VCN_ID | jq -r .data[0].id)

  # Fetch worker-0's private IP OCID 
  NODE_ID=$(oci compute instance list --lifecycle-state RUNNING --display-name worker-0 | jq -r .data[0].id)
  VNIC_ID=$(oci compute instance list-vnics --instance-id $NODE_ID | jq -r '.data[0]["id"]')
  PRIVATE_IP_WORKER_0=$(oci network private-ip list --vnic-id $VNIC_ID | jq -r '.data[0]["id"]')
  # Fetch worker-1's private IP OCID  
  NODE_ID=$(oci compute instance list --lifecycle-state RUNNING --display-name worker-1 | jq -r .data[0].id)
  VNIC_ID=$(oci compute instance list-vnics --instance-id $NODE_ID | jq -r '.data[0]["id"]')
  PRIVATE_IP_WORKER_1=$(oci network private-ip list --vnic-id $VNIC_ID | jq -r '.data[0]["id"]')
  # Fetch worker-2's private IP OCID  
  NODE_ID=$(oci compute instance list --lifecycle-state RUNNING --display-name worker-2 | jq -r .data[0].id)
  VNIC_ID=$(oci compute instance list-vnics --instance-id $NODE_ID | jq -r '.data[0]["id"]')
  PRIVATE_IP_WORKER_2=$(oci network private-ip list --vnic-id $VNIC_ID | jq -r '.data[0]["id"]')    
  
  INTERNET_GATEWAY_ID=$(oci network internet-gateway list --vcn-id $VCN_ID | jq -r '.data[0]["id"]')    
  
  oci network route-table update --rt-id $ROUTE_TABLE_ID --force --route-rules "[
  {
    \"destination\": \"0.0.0.0/0\",
    \"destination-type\": \"CIDR_BLOCK\",
    \"network-entity-id\": \"$INTERNET_GATEWAY_ID\"
  },
  {
    \"destination\": \"10.200.0.0/24\",
    \"destination-type\": \"CIDR_BLOCK\",
    \"network-entity-id\": \"$PRIVATE_IP_WORKER_0\"
  },
  {
    \"destination\": \"10.200.1.0/24\",
    \"destination-type\": \"CIDR_BLOCK\",
    \"network-entity-id\": \"$PRIVATE_IP_WORKER_1\"
  },
  {
    \"destination\": \"10.200.2.0/24\",
    \"destination-type\": \"CIDR_BLOCK\",
    \"network-entity-id\": \"$PRIVATE_IP_WORKER_2\"
  }    
]"
}
```

Next: [Deploying the DNS Cluster Add-on](12-dns-addon.md)
