# Cleaning Up

In this lab you will delete the compute resources created during this tutorial.

<details open>
<summary>GCP</summary>

## Compute Instances

Delete the controller and worker compute instances:

```
gcloud -q compute instances delete \
  controller-0 controller-1 controller-2 \
  worker-0 worker-1 worker-2
```

## Networking

Delete the external load balancer network resources:

```
{
  gcloud -q compute forwarding-rules delete kubernetes-forwarding-rule \
    --region $(gcloud config get-value compute/region)

  gcloud -q compute target-pools delete kubernetes-target-pool

  gcloud -q compute http-health-checks delete kubernetes

  gcloud -q compute addresses delete kubernetes-the-hard-way
}
```

Delete the `kubernetes-the-hard-way` firewall rules:

```
gcloud -q compute firewall-rules delete \
  kubernetes-the-hard-way-allow-nginx-service \
  kubernetes-the-hard-way-allow-internal \
  kubernetes-the-hard-way-allow-external \
  kubernetes-the-hard-way-allow-health-check
```

Delete the `kubernetes-the-hard-way` network VPC:

```
{
  gcloud -q compute routes delete \
    kubernetes-route-10-200-0-0-24 \
    kubernetes-route-10-200-1-0-24 \
    kubernetes-route-10-200-2-0-24

  gcloud -q compute networks subnets delete kubernetes

  gcloud -q compute networks delete kubernetes-the-hard-way
}
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
for host in controller-0 controller-1 controller-2 worker-0 worker-1 worker-2; do
  INSTANCE_ID="$(aws ec2 describe-instances \
    --filters \
      Name=vpc-id,Values="$VPC_ID" \
      Name=tag:Name,Values="$host" \
    --profile kubernetes-the-hard-way \
    --query 'Reservations[].Instances[].InstanceId' \
    --output text)"

  aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --profile kubernetes-the-hard-way
done

aws iam remove-role-from-instance-profile \
  --instance-profile-name kubernetes-the-hard-way \
  --role-name kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way

aws iam delete-instance-profile \
  --instance-profile-name kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way

aws iam delete-role-policy \
  --role-name kubernetes-the-hard-way \
  --policy-name kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way

aws iam delete-role \
  --role-name kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way

aws ec2 delete-key-pair \
  --key-name kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way

# After all ec2 instances have been terminated.
aws elb delete-load-balancer \
  --load-balancer-name kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way

INTERNET_GATEWAY_ID="$(aws ec2 describe-internet-gateways \
  --filter Name=tag-key,Values=kubernetes.io/cluster/kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way \
  --query 'InternetGateways[0].InternetGatewayId' \
  --output text)"

aws ec2 detach-internet-gateway \
  --internet-gateway-id "$INTERNET_GATEWAY_ID" \
  --vpc-id "$VPC_ID" \
  --profile kubernetes-the-hard-way

aws ec2 delete-internet-gateway \
  --internet-gateway-id "$INTERNET_GATEWAY_ID" \
  --profile kubernetes-the-hard-way

SECURITY_GROUP_ID="$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way \
  --query 'SecurityGroups[0].GroupId' \
  --output text)"

aws ec2 delete-security-group \
  --group-id "$SECURITY_GROUP_ID" \
  --profile kubernetes-the-hard-way

SUBNET_ID="$(aws ec2 describe-subnets \
  --filters Name=tag-key,Values=kubernetes.io/cluster/kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way \
  --query 'Subnets[0].SubnetId' \
  --output text)"

aws ec2 delete-subnet \
  --subnet-id "$SUBNET_ID" \
  --profile kubernetes-the-hard-way

ROUTE_TABLE_ID="$(aws ec2 describe-route-tables \
  --filter Name=tag-key,Values=kubernetes.io/cluster/kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way \
  --query 'RouteTables[0].RouteTableId' \
  --output text)"

aws ec2 delete-route-table \
  --route-table-id "$ROUTE_TABLE_ID" \
  --profile kubernetes-the-hard-way

aws ec2 delete-vpc \
  --vpc-id "$VPC_ID" \
  --profile kubernetes-the-hard-way

DHCP_OPTION_SET_ID="$(aws ec2 describe-dhcp-options \
  --filters Name=tag-key,Values=kubernetes.io/cluster/kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way \
  --query 'DhcpOptions[0].DhcpOptionsId' \
  --output text)"

aws ec2 delete-dhcp-options \
  --dhcp-options-id "$DHCP_OPTION_SET_ID" \
  --profile kubernetes-the-hard-way
```

</details>
