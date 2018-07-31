# Provisioning Pod Network Routes

Pods scheduled to a node receive an IP address from the node's Pod CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing network [routes](https://cloud.google.com/compute/docs/vpc/routes).

In this lab you will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address.

> There are [other ways](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) to implement the Kubernetes networking model.

## The Routing Table

In this section you will gather the information required to create routes in the `kubernetes-the-hard-way` VPC network.

Print the internal IP address and Pod CIDR range for each worker instance:

<details open>
<summary>GCP</summary>

```
for instance in worker-0 worker-1 worker-2; do
  gcloud compute instances describe ${instance} \
    --format 'value[separator=" "](networkInterfaces[0].networkIP,metadata.items[0].value)'
done
```

</details>

<details>
<summary>AWS</summary>

```
VPC_ID="$(aws ec2 describe-vpcs \
  --filters Name=tag-key,Values=kubernetes.io/cluster/kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way \
  --query 'Vpcs[0].VpcId' \
  --output text)"
```
```
for i in 0 1 2; do
  instance_id="$(aws ec2 describe-instances \
    --filters \
      Name=vpc-id,Values="$VPC_ID" \
      Name=tag:Name,Values="worker-$i" \
    --profile kubernetes-the-hard-way \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)"

  instance_ip="$(aws ec2 describe-instances \
    --instance-ids "$instance_id" \
    --profile kubernetes-the-hard-way \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)"

  instance_ud="$(aws ec2 describe-instance-attribute \
    --instance-id "$instance_id" \
    --attribute userData \
    --profile kubernetes-the-hard-way \
    --query UserData.Value \
    --output text|base64 --decode)"

  pod_cidr="$(echo "$instance_ud"|tr '|' '\n'|grep '^pod-cidr='|cut -d= -f2)"

  echo "$instance_ip $pod_cidr"
done
```

</details>
<p></p>

> output

```
10.240.0.20 10.200.0.0/24
10.240.0.21 10.200.1.0/24
10.240.0.22 10.200.2.0/24
```

## Routes

Create network routes for each worker instance:

<details open>
<summary>GCP</summary>

```
for i in 0 1 2; do
  gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
    --network kubernetes-the-hard-way \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done
```

</details>

<details>
<summary>AWS</summary>

```
ROUTE_TABLE_ID="$(aws ec2 describe-route-tables \
  --filters \
    Name=vpc-id,Values="$VPC_ID" \
    Name=tag-key,Values=kubernetes.io/cluster/kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way \
  --query 'RouteTables[0].RouteTableId' \
  --output text)"

for i in 0 1 2; do
  instance_id="$(aws ec2 describe-instances \
    --filters \
      Name=vpc-id,Values="$VPC_ID" \
      Name=tag:Name,Values="worker-$i" \
    --profile kubernetes-the-hard-way \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)"

  instance_ud="$(aws ec2 describe-instance-attribute \
    --instance-id "$instance_id" \
    --attribute userData \
    --profile kubernetes-the-hard-way \
    --query UserData.Value \
    --output text|base64 --decode)"

  pod_cidr="$(echo "$instance_ud"|tr '|' '\n'|grep '^pod-cidr='|cut -d= -f2)"

  aws ec2 create-route \
    --route-table-id "$ROUTE_TABLE_ID" \
    --destination-cidr-block "$pod_cidr" \
    --instance-id "$instance_id" \
    --profile kubernetes-the-hard-way
done
```

</details>
<p></p>

List the routes in the `kubernetes-the-hard-way` VPC network:

<details open>
<summary>GCP</summary>

```
gcloud compute routes list --filter "network: kubernetes-the-hard-way"
```

</details>

<details>
<summary>AWS</summary>

```
aws ec2 describe-route-tables \
  --route-table-id "$ROUTE_TABLE_ID" \
  --profile kubernetes-the-hard-way \
  --query 'RouteTables[0].Routes[]|sort_by(@, &DestinationCidrBlock)[].[InstanceId,DestinationCidrBlock,GatewayId]' \
  --output table
```

</details>
<p></p>

> output

<details open>
<summary>GCP</summary>

```
NAME                            NETWORK                  DEST_RANGE     NEXT_HOP                  PRIORITY
default-route-236a40a8bc992b5b  kubernetes-the-hard-way  0.0.0.0/0      default-internet-gateway  1000
default-route-df77b1e818a56b30  kubernetes-the-hard-way  10.240.0.0/24                            1000
kubernetes-route-10-200-0-0-24  kubernetes-the-hard-way  10.200.0.0/24  10.240.0.20               1000
kubernetes-route-10-200-1-0-24  kubernetes-the-hard-way  10.200.1.0/24  10.240.0.21               1000
kubernetes-route-10-200-2-0-24  kubernetes-the-hard-way  10.200.2.0/24  10.240.0.22               1000
```

</details>

<details>
<summary>AWS</summary>

```
----------------------------------------------------------
|                   DescribeRouteTables                  |
+---------------------+-----------------+----------------+
|  None               |  0.0.0.0/0      |  igw-116a3177  |
|  i-0d173dd08280c9f52|  10.200.0.0/24  |  None          |
|  i-0a4ae7e79b0bc3cc9|  10.200.1.0/24  |  None          |
|  i-0a424b69034b9068f|  10.200.2.0/24  |  None          |
|  None               |  10.240.0.0/24  |  local         |
+---------------------+-----------------+----------------+
```

</details>
<p></p>

Next: [Deploying the DNS Cluster Add-on](12-dns-addon.md)
