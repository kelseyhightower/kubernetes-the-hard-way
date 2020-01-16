# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this lab you will provision the compute resources required for running a secure and highly available Kubernetes cluster across a single [availability zone](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html) on AWS.

> Ensure a default region has been set as described in the [Prerequisites](01-prerequisites.md) lab.

## Networking

The Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) assumes a flat network in which containers and nodes can communicate with each other. In cases where this is not desired [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can limit how groups of containers are allowed to communicate with each other and external network endpoints.

> Setting up network policies is out of scope for this tutorial.

### Amazon Virtual Private Cloud (VPC)

In this section a dedicated [Amazon Virtual Private Cloud](https://aws.amazon.com/vpc/) (VPC) network will be setup to host the Kubernetes cluster. The VPC should contain a public [subnet](https://docs.aws.amazon.com/vpc/latest/userguide//VPC_Subnets.html), routing rules, and security groups.

Here's a CloudFormation template that defines network resources:

Reference: [cloudformation/hard-k8s-network.cfn.yml](../cloudformation/hard-k8s-network.cfn.yml)
```yaml
Resources:
  HardK8sVpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: "10.240.0.0/16"
      EnableDnsHostnames: true
      EnableDnsSupport: true
  HardK8sSubnet:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref HardK8sVpc
      CidrBlock: "10.240.0.0/24"
      MapPublicIpOnLaunch: true
  # ...
```

Please note that the subnet `CidrBlock` must be provisioned with an IP address range large enough to assign a private IP address to each node in the Kubernetes cluster.

> The `10.240.0.0/24` IP address range can host up to 254 EC2 instances.

Now create network resources via AWS CLI command:

```
$ aws cloudformation create-stack \
  --stack-name hard-k8s-network \
  --template-body file://cloudformation/hard-k8s-network.cfn.yml
```


### Security Groups

Create a security group that meet following requirements:

* allows all internal traffic from VPC CIDR range (as defined above, `10.240.0.0/24`)
* allows all internal traffic from PODs CIDR range (it can be defined arbitrary - let's say `10.200.0.0/16`)
* allows external ingress TCP traffic on port 22 and 6443 from anywhere (`0.0.0.0/0`)
* allows external ingress ICMP traffic from anywhere (`0.0.0.0/0`)
* external egress traffic is allowed implicitly, so we don't need to define them.

Here's a CloudFormation template file to create a security group with requirements above.

Reference: [cloudformation/hard-k8s-security-groups.cfn.yml](../cloudformation/hard-k8s-security-groups.cfn.yml)
```yaml
Resources:
  HardK8sSg:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: security group for Kubernetes the hard way
      VpcId: !ImportValue hard-k8s-vpc
      SecurityGroupIngress:
      # ingress internal traffic - allow all protocols/ports
      - { "CidrIp": "10.240.0.0/24", "IpProtocol": "-1" } # master/worker nodes cidr range
      - { "CidrIp": "10.200.0.0/16", "IpProtocol": "-1" } # pod cidr range
      # ingress external traffic
      - { "CidrIp": "0.0.0.0/0", "IpProtocol": "tcp",  "FromPort": 6443, "ToPort":  6443 }
      - { "CidrIp": "0.0.0.0/0", "IpProtocol": "tcp",  "FromPort":   22, "ToPort":    22 } 
      - { "CidrIp": "0.0.0.0/0", "IpProtocol": "icmp", "FromPort":   -1, "ToPort":    -1 }
# ...
```

This security group will be used for master and worker nodes. It allows internal all traffic from `10.240.0.0/24` (which is the subnet CIDR range we've created above) and `10.200.0.0/16` 


Then create a CloudFormation stack to provision the security group.

```
$ aws cloudformation create-stack \
  --stack-name hard-k8s-security-groups \
  --template-body file://cloudformation/hard-k8s-security-groups.cfn.yml
```

List rules in the created security group:

```
$ aws ec2 describe-security-groups \
  --filters 'Name=description,Values="security group for Kubernetes the hard way"' \
  --query 'SecurityGroups[0].IpPermissions'

[
    {
        "IpProtocol": "-1",
        "IpRanges": [ { "CidrIp": "10.240.0.0/24" }, { "CidrIp": "10.200.0.0/16" } ],...
    },
    {
        "IpProtocol": "tcp",
        "IpRanges": [ { "CidrIp": "0.0.0.0/0" } ],
        "FromPort": 6443, "ToPort": 6443,...
    },
    {
        "IpProtocol": "tcp",
        "IpRanges": [ { "CidrIp": "0.0.0.0/0" } ],
        "FromPort": 22, "ToPort": 22,...
    },
    {
        "IpProtocol": "icmp",
        "IpRanges": [ { "CidrIp": "0.0.0.0/0" } ],
        "FromPort": -1, "ToPort": -1,...
    }
]
```

### Kubernetes Public IP Address

Using [Elastic IP Addresses (EIP)](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html) you can allocate a static IP address that will be attached to the [Network Load Balancer (NLB)](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html) fronting the Kubernetes API Servers.

Let's create an EIP which we'll use for NLB later.

Reference: [cloudformation/hard-k8s-eip.cfn.yml](../cloudformation/hard-k8s-eip.cfn.yml)
```yaml
Resources:
  HardK8sEIP:
    Type: AWS::EC2::EIP
    Properties: 
      Tags: 
        - Key: Name
          Value: eip-kubernetes-the-hard-way

Outputs:
  EipAllocation:
    Value: !GetAtt HardK8sEIP.AllocationId
    Export: { Name: hard-k8s-eipalloc }
```

Allocate Elastic IP Address via CloudFormation:

```
$ aws cloudformation create-stack \
  --stack-name hard-k8s-eip \
  --template-body file://cloudformation/hard-k8s-eip.cfn.yml
```

The EIP is tagged `eip-kubernetes-the-hard-way` as a name so that we can retrieve it easily.

```
$ aws ec2 describe-addresses --filters "Name=tag:Name,Values=eip-kubernetes-the-hard-way"
{
    "Addresses": [
        {
            "PublicIp": "x.xxx.xx.xx",
            "AllocationId": "eipalloc-xxxxxxxxxxxxxxxxx",
            "Domain": "vpc",
            "PublicIpv4Pool": "amazon",
            "Tags": [
                { "Key": "Name", "Value": "eip-kubernetes-the-hard-way" },...
            ]
        }
    ]
}
```

## EC2 instances

[Amazon EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html) instances in this lab will be provisioned using [Ubuntu Server](https://www.ubuntu.com/server) 18.04. Each EC2 instance will be provisioned with a fixed private IP address to simplify the Kubernetes bootstrapping process.

You connect EC2 instances via SSH so make sure you've created and have at least one SSH key pairs in your account and the region you're working on. For more information: [Amazon EC2 Key Pairs - Amazon Elastic Compute Cloud](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).

### Kubernetes Master nodes (Control Plane)

Create three EC2 instances which will host the Kubernetes control plane:

Reference: [cloudformation/hard-k8s-master-nodes.cfn.yml](../cloudformation/hard-k8s-master-nodes.cfn.yml)
```yaml
Resources:
  HardK8sMaster0:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: t3.micro
      SubnetId: !ImportValue hard-k8s-subnet
      SecurityGroupIds:
      - !ImportValue hard-k8s-sg
      ImageId:
        Fn::FindInMap: [UbuntuAMIs, !Ref "AWS::Region", "id"]
      KeyName: !Ref ParamKeyName
      PrivateIpAddress: 10.240.0.10
      UserData:
        Fn::Base64: |-
          #cloud-config
          fqdn: master-0.k8shardway.local
          hostname: master-0
          runcmd:
            - echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg
          write_files:
            - path: /etc/hosts
              permissions: '0644'
              content: |
                127.0.0.1   localhost localhost.localdomain
                # Kubernetes the Hard Way - hostnames
                10.240.0.10 master-0
                10.240.0.11 master-1
                10.240.0.12 master-2
                10.240.0.20 worker-0
                10.240.0.21 worker-1
                10.240.0.22 worker-2
      Tags: [ { "Key": "Name", "Value": "master-0" } ]
  # ...

Parameters:
  ParamKeyName:
    Type: AWS::EC2::KeyPair::KeyName
    Default: ec2-key

# $ aws ec2 describe-regions --query 'Regions[].RegionName' --output text \
#   | tr "\t" "\n" | sort \
#   | xargs -I _R_ aws --region _R_ ec2 describe-images \
#                      --filters Name=name,Values="ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20191002" \
#                      --query 'Images[0].ImageId' --output
Mappings:
  UbuntuAMIs:
    ap-northeast-1: { "id": "ami-0cd744adeca97abb1" }
    # ...

Outputs:
  Master0:
    Value: !Ref HardK8sMaster0
    Export: { Name: hard-k8s-master-0 }
  # ...
```

Note that we use cloud-config definitions to set hostname for each master node. They would be `master-0`, `master-1`, and `master-2` for master nodes (control plane).

Create master nodes via CloudFormation. Please note that you have to replace `<your_ssh_key_name>` with your EC2 key pair name.

```
$ aws ec2 describe-key-pairs --query 'KeyPairs[].KeyName'
[
    "my-key-name-1",
    "my-key-name-2"
]

$ aws cloudformation create-stack \
  --stack-name hard-k8s-master-nodes \
  --parameters ParameterKey=ParamKeyName,ParameterValue=<your_ssh_key_name> \
  --template-body file://cloudformation/hard-k8s-master-nodes.cfn.yml
```


### Kubernetes Worker nodes (Data Plane)

Each worker instance requires a pod subnet allocation from the Kubernetes cluster CIDR range. The pod subnet allocation will be used to configure container networking in a later exercise. We will use [instance UserData](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-add-user-data.html) to put pod subnet allocations information to EC2 instances' `/opt/pod_cidr.txt` at runtime.

> The Kubernetes cluster CIDR range is defined by the Controller Manager's `--cluster-cidr` flag. In this tutorial the cluster CIDR range will be set to `10.200.0.0/16`, which supports 254 subnets.

Create three EC2 instances which will host the Kubernetes worker nodes:

Reference: [cloudformation/hard-k8s-worker-nodes.cfn.yml](../cloudformation/hard-k8s-worker-nodes.cfn.yml)
```yaml
Resources:
  HardK8sWorker0:
    Type: AWS::EC2::Instance
    Properties:
      InstanceType: t3.micro
      SubnetId: !ImportValue hard-k8s-subnet
      SecurityGroupIds:
      - !ImportValue hard-k8s-sg
      ImageId:
        Fn::FindInMap: [UbuntuAMIs, !Ref "AWS::Region", "id"]
      KeyName: !Ref ParamKeyName
      PrivateIpAddress: 10.240.0.20
      UserData:
        Fn::Base64: |-
          Content-Type: multipart/mixed; boundary="//"
          # ...
          #cloud-config
          fqdn: worker-0.k8shardway.local
          hostname: worker-0
          runcmd:
            - echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg
          write_files:
            - path: /etc/hosts
              permissions: '0644'
              content: |
                127.0.0.1   localhost localhost.localdomain
                # Kubernetes the Hard Way - hostnames
                10.240.0.10 master-0
                10.240.0.11 master-1
                10.240.0.12 master-2
                10.240.0.20 worker-0
                10.240.0.21 worker-1
                10.240.0.22 worker-2
          
          --//
          # ...
          #!/bin/bash
          echo 10.200.0.0/24 > /opt/pod_cidr.txt
          --//
      # ...
```

Here we use cloud-config to set hostname like worker nodes. Worker nodes' hostname would be `worker-0`, `worker-1`, and `worker-2` for worker nodes (data plane). Also using [Mime multi-part](https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html) contents for [cloud-init UserData Formats](https://cloudinit.readthedocs.io/en/latest/topics/format.html), we define shell script that save PODs CIDR range in the instance filesystem `/opt/pod_cidr.txt` as well.

Create worker nodes via CloudFormation.

```
$ aws cloudformation create-stack \
  --stack-name hard-k8s-worker-nodes \
  --parameters ParameterKey=ParamKeyName,ParameterValue=<your_ssh_key> \
  --template-body file://cloudformation/hard-k8s-worker-nodes.cfn.yml
```


### Verification of nodes

List the instances in your newly created VPC:

```
$ aws cloudformation describe-stacks --stack-name hard-k8s-network --query 'Stacks[0].Outputs[].OutputValue'
[
    "vpc-xxxxxxxxxxxxxxxxx",
    "subnet-yyyyyyyyyyyyyyyyy",
    "rtb-zzzzzzzzzzzzzzzzz"
]

$ VPC_ID=$(aws cloudformation describe-stacks \
  --stack-name hard-k8s-network \
  --query 'Stacks[0].Outputs[?ExportName==`hard-k8s-vpc`].OutputValue' --output text)

$ aws ec2 describe-instances \
  --filters Name=vpc-id,Values=$VPC_ID \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value | [0],InstanceId,Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress,State.Name]' \
  --output text | sort

master-0    i-xxxxxxxxxxxxxxxxx    ap-northeast-1c   10.240.0.10    xx.xxx.xx.xxx   running
master-1    i-yyyyyyyyyyyyyyyyy    ap-northeast-1c   10.240.0.11    xx.xxx.xxx.xxx  running
master-2    i-zzzzzzzzzzzzzzzzz    ap-northeast-1c   10.240.0.12    xx.xxx.xx.xxx   running
worker-0    i-aaaaaaaaaaaaaaaaa    ap-northeast-1c   10.240.0.20    x.xxx.xx.xx     running
worker-1    i-bbbbbbbbbbbbbbbbb    ap-northeast-1c   10.240.0.21    xx.xxx.xx.xxx   running
worker-2    i-ccccccccccccccccc    ap-northeast-1c   10.240.0.22    xx.xxx.xxx.xxx  running
```


## Verifying SSH Access

As mentioned above, SSH will be used to configure the master and worker instances. We have already configured master and worker instances with `KeyName` property, you can connect instances via ssh. For more details please take a look at the documentation: [Connecting to Your Linux Instance Using SSH - Amazon Elastic Compute Cloud](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html)

Let's test SSH access to the `master-0` EC2 instance via its Public IP address:

```
$ ssh -i ~/.ssh/your_ssh_key ubuntu@xx.xxx.xx.xxx
# ...
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'xx.xxx.xx.xxx' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 18.04.3 LTS (GNU/Linux 4.15.0-1051-aws x86_64)
# ...
ubuntu@master-0:~$
```

Type `exit` at the prompt to exit the `master-0` instance:

```
ubuntu@master-0:~$ exit

logout
Connection to xx.xxx.xx.xxx closed.
```

Next: [Provisioning a CA and Generating TLS Certificates](04-certificate-authority.md)