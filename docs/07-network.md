# Managing the Container Network Routes

Now that each worker node is online we need to add routes to make sure that Pods running on different machines can talk to each other. In this lab we are not going to provision any overlay networks and instead rely on Layer 3 networking. That means we need to add routes to our router. In GCP each network has a router that can be configured. If this was an on-prem datacenter then ideally you would need to add the routes to your local router.

## Get the Routing Table

The first thing we need to do is gather the information required to populate the router table. We need the Internal IP address and Pod Subnet for each of the worker nodes.

Use `kubectl` to print the `InternalIP` and `podCIDR` for each worker node:

```
kubectl get nodes \
  --output=jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address} {.spec.podCIDR} {"\n"}{end}'
```

Output:

```
10.240.0.30 10.200.0.0/24 
10.240.0.31 10.200.1.0/24 
10.240.0.32 10.200.2.0/24 
```

## Create Routes

### GCP

```
gcloud compute routes create kubernetes-route-10-200-0-0-24 \
  --network kubernetes \
  --next-hop-address 10.240.0.30 \
  --destination-range 10.200.0.0/24
```

```
gcloud compute routes create kubernetes-route-10-200-1-0-24 \
  --network kubernetes \
  --next-hop-address 10.240.0.31 \
  --destination-range 10.200.1.0/24
```

```
gcloud compute routes create kubernetes-route-10-200-2-0-24 \
  --network kubernetes \
  --next-hop-address 10.240.0.32 \
  --destination-range 10.200.2.0/24
```

### AWS

```
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=kubernetes" | \
  jq -r '.RouteTables[].RouteTableId')
```

```
WORKER_0_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=worker0" | \
  jq -j '.Reservations[].Instances[].InstanceId')
```

```
aws ec2 create-route \
  --route-table-id ${ROUTE_TABLE_ID} \
  --destination-cidr-block 10.200.0.0/24 \
  --instance-id ${WORKER_0_INSTANCE_ID}
```

```
WORKER_1_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=worker1" | \
  jq -j '.Reservations[].Instances[].InstanceId')
```

```
aws ec2 create-route \
  --route-table-id ${ROUTE_TABLE_ID} \
  --destination-cidr-block 10.200.1.0/24 \
  --instance-id ${WORKER_1_INSTANCE_ID}
```

```
WORKER_2_INSTANCE_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=worker2" | \
  jq -j '.Reservations[].Instances[].InstanceId')
```

```
aws ec2 create-route \
  --route-table-id ${ROUTE_TABLE_ID} \
  --destination-cidr-block 10.200.2.0/24 \
  --instance-id ${WORKER_2_INSTANCE_ID}
```
