# Cleaning Up

## GCP

### Virtual Machines

```
gcloud compute instances delete \
  controller0 controller1 controller2 \
  worker0 worker1 worker2 \
  etcd0 etcd1 etcd2
```

### Networking

```
gcloud compute forwarding-rules delete kubernetes-rule
```

```
gcloud compute target-pools delete kubernetes-pool
```

```
gcloud compute http-health-checks delete kube-apiserver-check
```

```
gcloud compute addresses delete kubernetes
```


```
gcloud compute firewall-rules delete \
  kubernetes-allow-api-server \
  kubernetes-allow-healthz \
  kubernetes-allow-icmp \
  kubernetes-allow-internal \
  kubernetes-allow-rdp \
  kubernetes-nginx-service \
  kubernetes-allow-ssh
```

```
gcloud compute routes delete \
  kubernetes-route-10-200-0-0-24 \
  kubernetes-route-10-200-1-0-24 \
  kubernetes-route-10-200-2-0-24
```

```
gcloud compute networks subnets delete kubernetes
```

```
gcloud compute networks delete kubernetes
```


## AWS

### Virtual Machines

```
KUBERNETES_HOSTS=(controller0 controller1 controller2 etcd0 etcd1 etcd2 worker0 worker1 worker2)
```

```
for host in ${KUBERNETES_HOSTS[*]}; do
  INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${host}" | \
    jq -j '.Reservations[].Instances[].InstanceId')
  aws ec2 terminate-instances --instance-ids ${INSTANCE_ID}
done
```

### IAM

```
aws iam remove-role-from-instance-profile \
  --instance-profile-name kubernetes \
  --role-name kubernetes
```

```
aws iam delete-instance-profile \
  --instance-profile-name kubernetes
```

```
aws iam delete-role-policy \
  --role-name kubernetes \
  --policy-name kubernetes
```

```
aws iam delete-role --role-name kubernetes
```

### SSH Keys

```
aws ec2 delete-key-pair --key-name kubernetes
```

### Networking

Be sure to wait about a minute for all VMs to terminates to avoid the following errors:

```
An error occurred (DependencyViolation) when calling ...
```

Network resources cannot be deleted while VMs hold a reference to them.

#### Load Balancers

```
aws elb delete-load-balancer \
  --load-balancer-name kubernetes
```

#### Internet Gateways

```
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=kubernetes" | \
  jq -r '.Vpcs[].VpcId')
```

```
INTERNET_GATEWAY_ID=$(aws ec2 describe-internet-gateways \
  --filters "Name=tag:Name,Values=kubernetes" | \
  jq -r '.InternetGateways[].InternetGatewayId')
```

```
aws ec2 detach-internet-gateway \
  --internet-gateway-id ${INTERNET_GATEWAY_ID} \
  --vpc-id ${VPC_ID}
```

```
aws ec2 delete-internet-gateway \
  --internet-gateway-id ${INTERNET_GATEWAY_ID}
```

#### Security Groups

```
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=kubernetes" | \
  jq -r '.SecurityGroups[].GroupId')
```

```
aws ec2 delete-security-group \
  --group-id ${SECURITY_GROUP_ID}
```

#### Subnets

```
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=kubernetes" | \
  jq -r '.Subnets[].SubnetId')
```

```
aws ec2 delete-subnet --subnet-id ${SUBNET_ID}
```

#### Route Tables

```
ROUTE_TABLE_ID=$(aws ec2 describe-route-tables \
  --filters "Name=tag:Name,Values=kubernetes" | \
  jq -r '.RouteTables[].RouteTableId')
```

```
aws ec2 delete-route-table --route-table-id ${ROUTE_TABLE_ID}
```

#### VPC

```
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=kubernetes" | \
  jq -r '.Vpcs[].VpcId')
```

```
aws ec2 delete-vpc --vpc-id ${VPC_ID}
```

#### DHCP Option Sets

```
DHCP_OPTION_SET_ID=$(aws ec2 describe-dhcp-options \
  --filters "Name=tag:Name,Values=kubernetes" | \
  jq -r '.DhcpOptions[].DhcpOptionsId')
```

```
aws ec2 delete-dhcp-options \
  --dhcp-options-id ${DHCP_OPTION_SET_ID}
```
