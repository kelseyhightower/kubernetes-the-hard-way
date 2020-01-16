# Provisioning Pod Network Routes

Pods scheduled to a node receive an IP address from the node's Pod CIDR range. At this point pods can not communicate with other pods running on different nodes due to missing [network routes](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html).

In this lab, firstly you will create a route for each worker node that maps the node's Pod CIDR range to the node's internal IP address.

> There are [other ways](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this) to implement the Kubernetes networking model.


## The Routing Table

In this section you will gather the information required to create new routes in the VPC network. Remember that we have created a route table for our dedicated subnet for the k8s cluster. What we need to do in this section would be adding new routes resources into the existing route table (which we can refer with `!ImportValue hard-k8s-rtb`)

Reference: [cloudformation/hard-k8s-pod-routes.cfn.yml](../cloudformation/hard-k8s-pod-routes.cfn.yml)
```yaml
Resources:
  RouteWorker0:
    Type: AWS::EC2::Route
    Properties:
      DestinationCidrBlock: 10.200.0.0/24
      RouteTableId: !ImportValue hard-k8s-rtb
      InstanceId: !ImportValue  hard-k8s-worker-0

  RouteWorker1:
    Type: AWS::EC2::Route
    Properties:
      DestinationCidrBlock: 10.200.1.0/24
      RouteTableId: !ImportValue hard-k8s-rtb
      InstanceId: !ImportValue  hard-k8s-worker-1

  RouteWorker2:
    Type: AWS::EC2::Route
    Properties:
      DestinationCidrBlock: 10.200.2.0/24
      RouteTableId: !ImportValue hard-k8s-rtb
      InstanceId: !ImportValue  hard-k8s-worker-2
```

Now create network resources via AWS CLI command:

```
$ aws cloudformation create-stack \
  --stack-name hard-k8s-pod-routes \
  --template-body file://cloudformation/hard-k8s-pod-routes.cfn.yml
```

Verify:

```
$ aws cloudformation describe-stacks \
  --stack-name hard-k8s-network \
  --query 'Stacks[0].Outputs' --output table
-----------------------------------------------------------------
|                        DescribeStacks                         |
+-----------------+----------------+----------------------------+
|   ExportName    |   OutputKey    |        OutputValue         |
+-----------------+----------------+----------------------------+
|  hard-k8s-rtb   |  RouteTableId  |  rtb-sssssssssssssssss     |
|  hard-k8s-vpc   |  VpcId         |  vpc-ppppppppppppppppp     |
|  hard-k8s-subnet|  SubnetId      |  subnet-qqqqqqqqqqqqqqqqq  |
+-----------------+----------------+----------------------------+

$ ROUTE_TABLE_ID=$(aws cloudformation describe-stacks \
  --stack-name hard-k8s-network \
  --query 'Stacks[0].Outputs[?ExportName==`hard-k8s-rtb`].OutputValue' --output text)

$ aws ec2 describe-route-tables \
  --route-table-ids $ROUTE_TABLE_ID \
  --query 'RouteTables[0].Routes[].[DestinationCidrBlock,InstanceId,GatewayId]' --output table
-------------------------------------------------------------------
|                       DescribeRouteTables                       |
+---------------+-----------------------+-------------------------+
|  10.200.0.0/24|  i-aaaaaaaaaaaaaaaaa  |  None                   | # worker-0
|  10.200.1.0/24|  i-bbbbbbbbbbbbbbbbb  |  None                   | # worker-1
|  10.200.2.0/24|  i-ccccccccccccccccc  |  None                   | # worker-2
|  10.240.0.0/16|  None                 |  local                  | # inter-vpc traffic among 10.240.0.0/16 range
|  0.0.0.0/0    |  None                 |  igw-xxxxxxxxxxxxxxxxx  | # default internet gateway
+---------------+-----------------------+-------------------------+
```

So this route table ensure traffic to pods working on worker-0, which has IP CIDR range `10.200.0.0/24`, should be routed to worker-0 node.

Next: [Deploying the DNS Cluster Add-on](12-dns-addon.md)