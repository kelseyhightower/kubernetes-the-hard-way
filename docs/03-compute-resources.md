# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this lab you will provision the compute resources required for running a secure and highly available Kubernetes cluster across a single [compute zone](https://cloud.google.com/compute/docs/regions-zones/regions-zones).

> Ensure a default compute zone and region have been set as described in the [Prerequisites](01-prerequisites.md#set-a-default-compute-region-and-zone) lab.

## Networking

The Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) assumes a flat network in which containers and nodes can communicate with each other. In cases where this is not desired [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can limit how groups of containers are allowed to communicate with each other and external network endpoints.

> Setting up network policies is out of scope for this tutorial.

### Virtual Private Cloud Network


In this section a dedicated [Virtual Private Cloud](https://cloud.google.com/compute/docs/networks-and-firewalls#networks) (VPC) network will be setup to host the Kubernetes cluster.

Create the `kubernetes-the-hard-way` custom VPC network:

<details open>
<summary>GCP</summary>

```
gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom
```

</details>

<details>
<summary>AWS</summary>

```
VPC_ID="$(aws ec2 create-vpc \
  --cidr-block 10.240.0.0/24 \
  --profile kubernetes-the-hard-way \
  --query Vpc.VpcId \
  --output text)"
```
```
for opt in support hostnames; do
  aws ec2 modify-vpc-attribute \
    --vpc-id "$VPC_ID" \
    --enable-dns-"$opt" '{"Value": true}' \
    --profile kubernetes-the-hard-way
done

aws ec2 create-tags \
  --resources "$VPC_ID" \
  --tags Key=kubernetes.io/cluster/kubernetes-the-hard-way,Value=shared \
  --profile kubernetes-the-hard-way
```

</details>
<p></p>

A [subnet](https://cloud.google.com/compute/docs/vpc/#vpc_networks_and_subnets) must be provisioned with an IP address range large enough to assign a private IP address to each node in the Kubernetes cluster.

<details open>
<summary>GCP</summary>

Create the `kubernetes` subnet in the `kubernetes-the-hard-way` VPC network:

```
gcloud compute networks subnets create kubernetes \
  --network kubernetes-the-hard-way \
  --range 10.240.0.0/24
```

</details>

<details>
<summary>AWS</summary>

```
DHCP_OPTIONS_ID="$(aws ec2 create-dhcp-options \
  --dhcp-configuration \
    "Key=domain-name,Values=$(aws configure get region --profile kubernetes-the-hard-way).compute.internal" \
    "Key=domain-name-servers,Values=AmazonProvidedDNS" \
  --profile kubernetes-the-hard-way \
  --query DhcpOptions.DhcpOptionsId \
  --output text)"

aws ec2 create-tags \
  --resources "$DHCP_OPTIONS_ID" \
  --tags Key=kubernetes.io/cluster/kubernetes-the-hard-way,Value=shared \
  --profile kubernetes-the-hard-way

aws ec2 associate-dhcp-options \
  --dhcp-options-id "$DHCP_OPTIONS_ID" \
  --vpc-id "$VPC_ID" \
  --profile kubernetes-the-hard-way

SUBNET_ID="$(aws ec2 create-subnet \
  --vpc-id "$VPC_ID" \
  --cidr-block 10.240.0.0/24 \
  --profile kubernetes-the-hard-way \
  --query Subnet.SubnetId \
  --output text)"

aws ec2 create-tags \
  --resources "$SUBNET_ID" \
  --tags Key=kubernetes.io/cluster/kubernetes-the-hard-way,Value=shared \
  --profile kubernetes-the-hard-way

INTERNET_GATEWAY_ID="$(aws ec2 create-internet-gateway \
  --profile kubernetes-the-hard-way \
  --query InternetGateway.InternetGatewayId \
  --output text)"

aws ec2 create-tags \
  --resources "$INTERNET_GATEWAY_ID" \
  --tags Key=kubernetes.io/cluster/kubernetes-the-hard-way,Value=shared \
  --profile kubernetes-the-hard-way

aws ec2 attach-internet-gateway \
  --internet-gateway-id "$INTERNET_GATEWAY_ID" \
  --vpc-id "$VPC_ID" \
  --profile kubernetes-the-hard-way

ROUTE_TABLE_ID="$(aws ec2 create-route-table \
  --vpc-id "$VPC_ID" \
  --profile kubernetes-the-hard-way \
  --query RouteTable.RouteTableId \
  --output text)"

aws ec2 create-tags \
  --resources "$ROUTE_TABLE_ID" \
  --tags Key=kubernetes.io/cluster/kubernetes-the-hard-way,Value=shared \
  --profile kubernetes-the-hard-way

aws ec2 associate-route-table \
  --route-table-id "$ROUTE_TABLE_ID" \
  --subnet-id "$SUBNET_ID" \
  --profile kubernetes-the-hard-way

aws ec2 create-route \
  --route-table-id "$ROUTE_TABLE_ID" \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "$INTERNET_GATEWAY_ID" \
  --profile kubernetes-the-hard-way
```

</details>
<p></p>

> The `10.240.0.0/24` IP address range can host up to 254 compute instances.

### Firewall Rules

Create a firewall rule that allows internal communication across all protocols:

<details open>
<summary>GCP</summary>

```
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
  --allow tcp,udp,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 10.240.0.0/24,10.200.0.0/16
```

</details>

<details>
<summary>AWS</summary>

```
SECURITY_GROUP_ID="$(aws ec2 create-security-group \
  --group-name kubernetes-the-hard-way \
  --description kubernetes-the-hard-way \
  --vpc-id "$VPC_ID" \
  --profile kubernetes-the-hard-way \
  --query GroupId \
  --output text)"

aws ec2 create-tags \
  --resources "$SECURITY_GROUP_ID" \
  --tags Key=kubernetes.io/cluster/kubernetes-the-hard-way,Value=shared \
  --profile kubernetes-the-hard-way
```
```
allow() {
  aws ec2 authorize-security-group-ingress \
    --profile kubernetes-the-hard-way \
    --group-id "$SECURITY_GROUP_ID" \
    "$@"
}

allow --protocol all --source-group "$SECURITY_GROUP_ID"

for network in 10.200.0.0/16 10.240.0.0/24; do
  allow --protocol all --cidr "$network"
done
```

</details>
<p></p>

Create a firewall rule that allows external SSH, ICMP, and HTTPS:

<details open>
<summary>GCP</summary>

```
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 0.0.0.0/0
```

> An [external load balancer](https://cloud.google.com/compute/docs/load-balancing/network/) will be used to expose the Kubernetes API Servers to remote clients.

</details>

<details>
<summary>AWS</summary>

```
allow --protocol icmp --port 3-4 --cidr 0.0.0.0/0

for port in 22 6443; do
  allow --protocol tcp --port "$port" --cidr 0.0.0.0/0
done
```

> An [external load balancer](https://aws.amazon.com/elasticloadbalancing/) will be used to expose the Kubernetes API Servers to remote clients.

</details>
<p></p>

List the firewall rules in the `kubernetes-the-hard-way` VPC network:

<details open>
<summary>GCP</summary>

```
gcloud compute firewall-rules list --filter="network:kubernetes-the-hard-way"
```

> output

```
NAME                                    NETWORK                  DIRECTION  PRIORITY  ALLOW                 DENY
kubernetes-the-hard-way-allow-external  kubernetes-the-hard-way  INGRESS    1000      tcp:22,tcp:6443,icmp
kubernetes-the-hard-way-allow-internal  kubernetes-the-hard-way  INGRESS    1000      tcp,udp,icmp
```

</details>

<details>
<summary>AWS</summary>

```
aws ec2 describe-security-groups \
  --filters Name=group-id,Values="$SECURITY_GROUP_ID" \
  --profile kubernetes-the-hard-way \
  --query 'SecurityGroups[0].IpPermissions[].{GroupIds:UserIdGroupPairs[].GroupId,FromPort:FromPort,ToPort:ToPort,IpProtocol:IpProtocol,CidrIps:IpRanges[].CidrIp}' \
  --output table|\
  sed 's/| *DescribeSecurityGroups *|//g'|\
  tail -n +3
```

> output

```
+----------+--------------+----------+
| FromPort | IpProtocol   | ToPort   |
+----------+--------------+----------+
|  None    |  -1          |  None    |
+----------+--------------+----------+
||              CidrIps             ||
|+----------------------------------+|
||  10.200.0.0/16                   ||
||  10.240.0.0/24                   ||
|+----------------------------------+|
||             GroupIds             ||
|+----------------------------------+|
||  sg-b33811c3                     ||
|+----------------------------------+|

+----------+--------------+----------+
| FromPort | IpProtocol   | ToPort   |
+----------+--------------+----------+
|  22      |  tcp         |  22      |
+----------+--------------+----------+
||              CidrIps             ||
|+----------------------------------+|
||  0.0.0.0/0                       ||
|+----------------------------------+|

+----------+--------------+----------+
| FromPort | IpProtocol   | ToPort   |
+----------+--------------+----------+
|  6443    |  tcp         |  6443    |
+----------+--------------+----------+
||              CidrIps             ||
|+----------------------------------+|
||  0.0.0.0/0                       ||
|+----------------------------------+|

+----------+--------------+----------+
| FromPort | IpProtocol   | ToPort   |
+----------+--------------+----------+
|  3       |  icmp        |  4       |
+----------+--------------+----------+
||              CidrIps             ||
|+----------------------------------+|
||  0.0.0.0/0                       ||
|+----------------------------------+|
```

</details>

### Kubernetes Public IP Address

<details open>
<summary>GCP</summary>

Allocate a static IP address that will be attached to the external load balancer fronting the Kubernetes API Servers:

```
gcloud compute addresses create kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region)
```

Verify the `kubernetes-the-hard-way` static IP address was created in your default compute region:

```
gcloud compute addresses list --filter="name=('kubernetes-the-hard-way')"
```

> output

```
NAME                     REGION    ADDRESS        STATUS
kubernetes-the-hard-way  us-west1  XX.XXX.XXX.XX  RESERVED
```

</details>

<details>
<summary>AWS</summary>

```
aws elb create-load-balancer \
  --load-balancer-name kubernetes-the-hard-way \
  --listeners Protocol=TCP,LoadBalancerPort=6443,InstanceProtocol=TCP,InstancePort=6443 \
  --subnets "$SUBNET_ID" \
  --security-groups "$SECURITY_GROUP_ID" \
  --profile kubernetes-the-hard-way
```

> output

```
{
    "DNSName": "kubernetes-the-hard-way-382204365.us-west-2.elb.amazonaws.com"
}
```

</details>

## Compute Instances

The compute instances in this lab will be provisioned using [Ubuntu Server](https://www.ubuntu.com/server) 18.04, which has good support for the [containerd container runtime](https://github.com/containerd/containerd). Each compute instance will be provisioned with a fixed private IP address to simplify the Kubernetes bootstrapping process.

<details>
<summary>AWS</summary>

### Create Instance IAM Policies

```
cat >kubernetes-iam-role.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}
EOF

aws iam create-role \
  --role-name kubernetes-the-hard-way \
  --assume-role-policy-document file://kubernetes-iam-role.json \
  --profile kubernetes-the-hard-way

cat >kubernetes-iam-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Resource": "*",
    "Action": [
      "ec2:*",
      "elasticloadbalancing:*",
      "route53:*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage"
    ]
  }]
}
EOF

aws iam put-role-policy \
  --role-name kubernetes-the-hard-way \
  --policy-name kubernetes-the-hard-way \
  --policy-document file://kubernetes-iam-policy.json \
  --profile kubernetes-the-hard-way

aws iam create-instance-profile \
  --instance-profile-name kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way

aws iam add-role-to-instance-profile \
  --instance-profile-name kubernetes-the-hard-way \
  --role-name kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way
```

### Chosing an Image

```
IMAGE_ID="$(aws ec2 describe-images \
  --owners 099720109477 \
  --region "$(aws configure get region --profile kubernetes-the-hard-way)" \
  --filters \
    Name=root-device-type,Values=ebs \
    Name=architecture,Values=x86_64 \
    'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*' \
  --profile kubernetes-the-hard-way \
  --query 'sort_by(Images,&Name)[-1].ImageId' \
  --output text)"
```

</details>

### Kubernetes Controllers

Create three compute instances which will host the Kubernetes control plane:

<details open>
<summary>GCP</summary>

```
for i in 0 1 2; do
  gcloud compute instances create controller-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,controller
done
```

</details>

<details>
<summary>AWS</summary>

```
# For ssh access to ec2 machines.
aws ec2 create-key-pair \
  --key-name kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way \
  --query KeyMaterial \
  --output text >~/.ssh/kubernetes-the-hard-way

chmod 600 ~/.ssh/kubernetes-the-hard-way

for i in 0 1 2; do
  instance_id="$(aws ec2 run-instances \
    --associate-public-ip-address \
    --iam-instance-profile Name=kubernetes-the-hard-way \
    --image-id "$IMAGE_ID" \
    --count 1 \
    --key-name kubernetes-the-hard-way \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --instance-type t2.small \
    --private-ip-address "10.240.0.1$i" \
    --subnet-id "$SUBNET_ID" \
    --user-data "name=controller-$i" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=controller-$i},{Key=kubernetes.io/cluster/kubernetes-the-hard-way,Value=shared}]" \
    --profile kubernetes-the-hard-way \
    --query 'Instances[].InstanceId' \
    --output text)"

  aws ec2 modify-instance-attribute \
    --instance-id "$instance_id" \
    --no-source-dest-check \
    --profile kubernetes-the-hard-way
done
```

</details>

### Kubernetes Workers

Each worker instance requires a pod subnet allocation from the Kubernetes cluster CIDR range. The pod subnet allocation will be used to configure container networking in a later exercise. The `pod-cidr` instance metadata will be used to expose pod subnet allocations to compute instances at runtime.

> The Kubernetes cluster CIDR range is defined by the Controller Manager's `--cluster-cidr` flag. In this tutorial the cluster CIDR range will be set to `10.200.0.0/16`, which supports 254 subnets.

Create three compute instances which will host the Kubernetes worker nodes:

<details open>
<summary>GCP</summary>

```
for i in 0 1 2; do
  gcloud compute instances create worker-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --metadata pod-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,worker
done
```

</details>

<details>
<summary>AWS</summary>

```
for i in 0 1 2; do
  instance_id="$(aws ec2 run-instances \
    --associate-public-ip-address \
    --iam-instance-profile Name=kubernetes-the-hard-way \
    --image-id "$IMAGE_ID" \
    --count 1 \
    --key-name kubernetes-the-hard-way \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --instance-type t2.small \
    --private-ip-address "10.240.0.2$i" \
    --subnet-id "$SUBNET_ID" \
    --user-data "name=worker-$i|pod-cidr=10.200.$i.0/24" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=worker-$i},{Key=kubernetes.io/cluster/kubernetes-the-hard-way,Value=shared}]" \
    --profile kubernetes-the-hard-way \
    --query 'Instances[].InstanceId' \
    --output text)"

  aws ec2 modify-instance-attribute \
    --instance-id "$instance_id" \
    --no-source-dest-check \
    --profile kubernetes-the-hard-way
done
```

</details>

### Verification

List the compute instances in your default compute zone:

<details open>
<summary>GCP</summary>

```
gcloud compute instances list
```

> output

```
NAME          ZONE        MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
controller-0  us-west1-c  n1-standard-1               10.240.0.10  XX.XXX.XXX.XXX  RUNNING
controller-1  us-west1-c  n1-standard-1               10.240.0.11  XX.XXX.X.XX     RUNNING
controller-2  us-west1-c  n1-standard-1               10.240.0.12  XX.XXX.XXX.XX   RUNNING
worker-0      us-west1-c  n1-standard-1               10.240.0.20  XXX.XXX.XXX.XX  RUNNING
worker-1      us-west1-c  n1-standard-1               10.240.0.21  XX.XXX.XX.XXX   RUNNING
worker-2      us-west1-c  n1-standard-1               10.240.0.22  XXX.XXX.XX.XX   RUNNING
```

</details>

<details>
<summary>AWS</summary>

```
aws ec2 describe-instances \
  --filters \
    Name=instance-state-name,Values=running \
    Name=vpc-id,Values="$VPC_ID" \
  --profile kubernetes-the-hard-way \
  --query 'Reservations[].Instances[]|sort_by(@, &Tags[?Key==`Name`]|[0].Value)[].[Tags[?Key==`Name`]|[0].Value,InstanceId,Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress]' \
  --output table
```

> output

```
----------------------------------------------------------------------------------------
|                                   DescribeInstances                                  |
+--------------+-----------------------+-------------+--------------+------------------+
|  controller-0|  i-07c33497b7e6ee5ce  |  us-west-2a |  10.240.0.10 |  34.216.239.194  |
|  controller-1|  i-099ffe8ec525f6bdb  |  us-west-2a |  10.240.0.11 |  54.186.157.115  |
|  controller-2|  i-00c1800423320d12f  |  us-west-2a |  10.240.0.12 |  52.12.162.200   |
|  worker-0    |  i-00020c75b6703aa99  |  us-west-2a |  10.240.0.20 |  54.212.17.18    |
|  worker-1    |  i-0bf4c8f9f36012d0e  |  us-west-2a |  10.240.0.21 |  34.220.143.249  |
|  worker-2    |  i-0b4d2dd686ddd1e1a  |  us-west-2a |  10.240.0.22 |  35.165.251.149  |
+--------------+-----------------------+-------------+--------------+------------------+
```

</details>

## Configuring SSH Access

<details open>
<summary>GCP</summary>

SSH will be used to configure the controller and worker instances. When connecting to compute instances for the first time SSH keys will be generated for you and stored in the project or instance metadata as describe in the [connecting to instances](https://cloud.google.com/compute/docs/instances/connecting-to-instance) documentation.

Test SSH access to the `controller-0` compute instances:

```
gcloud compute ssh controller-0
```

If this is your first time connecting to a compute instance SSH keys will be generated for you. Enter a passphrase at the prompt to continue:

```
WARNING: The public SSH key file for gcloud does not exist.
WARNING: The private SSH key file for gcloud does not exist.
WARNING: You do not have an SSH key for gcloud.
WARNING: SSH keygen will be executed to generate a key.
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
```

At this point the generated SSH keys will be uploaded and stored in your project:

```
Your identification has been saved in /home/$USER/.ssh/google_compute_engine.
Your public key has been saved in /home/$USER/.ssh/google_compute_engine.pub.
The key fingerprint is:
SHA256:nz1i8jHmgQuGt+WscqP5SeIaSy5wyIJeL71MuV+QruE $USER@$HOSTNAME
The key's randomart image is:
+---[RSA 2048]----+
|                 |
|                 |
|                 |
|        .        |
|o.     oS        |
|=... .o .o o     |
|+.+ =+=.+.X o    |
|.+ ==O*B.B = .   |
| .+.=EB++ o      |
+----[SHA256]-----+
Updating project ssh metadata...-Updated [https://www.googleapis.com/compute/v1/projects/$PROJECT_ID].
Updating project ssh metadata...done.
Waiting for SSH key to propagate.
```

After the SSH keys have been updated you'll be logged into the `controller-0` instance:

```
Welcome to Ubuntu 18.04 LTS (GNU/Linux 4.15.0-1006-gcp x86_64)

...

Last login: Sun May 13 14:34:27 2018 from XX.XXX.XXX.XX
```

Type `exit` at the prompt to exit the `controller-0` compute instance:

```
$USER@controller-0:~$ exit
```
> output

```
logout
Connection to XX.XXX.XXX.XXX closed
```

</details>

<details>
<summary>AWS</summary>

```
get_ip() {
  aws ec2 describe-instances \
    --filters \
      Name=vpc-id,Values="$VPC_ID" \
      Name=tag:Name,Values="$1" \
    --profile kubernetes-the-hard-way \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text
}
```
```
ssh -i ~/.ssh/kubernetes-the-hard-way "ubuntu@$(get_ip controller-0)"
```

</details>
<p></p>

Next: [Provisioning a CA and Generating TLS Certificates](04-certificate-authority.md)
