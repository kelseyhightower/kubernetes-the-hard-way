# Cloud Infrastructure Provisioning - OpenStack

This lab will walk you through provisioning the compute instances required for running a H/A Kubernetes cluster. A total of 6 virtual machines will be created.

After completing this guide you should have the following compute instances:

```
openstack server list
```

````
+--------------------------------------+-----------------+-----------+----------------------------------------+---------------------+
| ID                                   | Name            | Status    | Networks                               | Image Name          |
+--------------------------------------+-----------------+-----------+----------------------------------------+---------------------+
| 17da9ba7-a0c3-415a-9fe2-b2729d4ba3da | worker2         | ACTIVE    | kubernetes=10.240.0.22                 | ubuntu-16.04        |
| d52281ba-0a76-4abf-addb-cd56c79d3f1d | worker1         | ACTIVE    | kubernetes=10.240.0.21                 | ubuntu-16.04        |
| f44c0c77-9810-4cf4-977e-45dafbe87074 | worker0         | ACTIVE    | kubernetes=10.240.0.20                 | ubuntu-16.04        |
| 96e690b4-e8cb-4733-aa1d-5262106181a2 | controller2     | ACTIVE    | kubernetes=10.240.0.12                 | ubuntu-16.04        |
| d69f09c1-00e5-465a-831c-446206461d28 | controller1     | ACTIVE    | kubernetes=10.240.0.11                 | ubuntu-16.04        |
| 80fc744c-d20e-4f24-9b10-c8a26ffbade3 | controller0     | ACTIVE    | kubernetes=10.240.0.10, 169.45.x.x     | ubuntu-16.04        |
+--------------------------------------+-----------------+-----------+----------------------------------------+---------------------+
````

> All machines will be provisioned with fixed private IP addresses to simplify the bootstrap process.

To make our Kubernetes control plane remotely accessible, a Floating IP address will be  assigned to one of the Kubernetes controllers. You can also assign floating IPs to all the nodes. In this example we're going to assign an IP to controller0 and use that to access the remailing nodes.

## Networking


Create a Kubernetes network:

```
openstack network create kubernetes
```

Create a subnet for the Kubernetes cluster:

```
openstack subnet create --network kubernetes \
   --subnet-range 10.240.0.0/24  kubernetes
```
Create a router for the network:

```
openstack router create kubernetes
```

Attach the network to the router:

```
openstack router add subnet kubernetes kubernetes
```

Attack the router to the external network:

```
neutron router-gateway-set kubernetes external
```


### Firewall Rules

First, create a security group:
```
openstack security group create kubernetes
```

```
openstack security group rule create \
  --ingress \
  --protocol icmp \
  --src-ip 0.0.0.0/0  \
  kubernetes
```

```
openstack security group rule create \
  --ingress --src-group kubernetes --protocol udp kubernetes
```

```
openstack security group rule create \
  --ingress --src-group kubernetes --protocol tcp kubernetes
```


```
openstack security group rule create \
  --ingress \
  --protocol tcp \
  --dst-port 3389 \
  --src-ip 0.0.0.0/0  \
  kubernetes

```

```
openstack security group rule create \
  --ingress \
  --protocol tcp \
  --dst-port 22 \
  --src-ip 0.0.0.0/0  \
  kubernetes
```

```
openstack security group rule create \
  --ingress \
  --protocol tcp \
  --dst-port 6443 \
  --src-ip 0.0.0.0/0  \
  kubernetes
```


```
openstack security group rule list kubernetes
```

```
+--------------------------------------+-------------+-----------+------------+--------------------------------------+
| ID                                   | IP Protocol | IP Range  | Port Range | Remote Security Group                |
+--------------------------------------+-------------+-----------+------------+--------------------------------------+
| 110fc25a-6cc7-409f-9b8f-40be05884203 | None        | None      |            | None                                 |
| 2327d33b-e497-4006-87e3-7991810b1686 | udp         | None      |            | 6f6399ef-b69b-49cb-9f97-8fcad96715bf |
| 2dfe89ce-c167-4f75-89df-a7bc3007336d | icmp        | 0.0.0.0/0 |            | None                                 |
| 2e175bd1-f885-41de-97af-0787be7fba9e | tcp         | 0.0.0.0/0 | 3389:3389  | None                                 |
| 39eaea13-92f5-438b-929c-d7585c84e4b2 | tcp         | 0.0.0.0/0 | 22:22      | None                                 |
| 5acea256-84b0-420d-923f-f257fe4e7319 | tcp         | 0.0.0.0/0 | 6443:6443  | None                                 |
| b6bc42d0-9f3f-4dcf-a5b1-7196968320d3 | tcp         | None      |            | 6f6399ef-b69b-49cb-9f97-8fcad96715bf |
| d1038338-bf4b-4f25-8c29-a104d74c2803 | None        | None      |            | None                                 |
+--------------------------------------+-------------+-----------+------------+--------------------------------------+
```

## Provision Virtual Machines

All the VMs in this lab will be provisioned using Ubuntu 16.04 mainly because it runs a newish Linux Kernel that has good support for Docker.

### Virtual Machines

#### Kubernetes Controllers

```
openstack server create --image ubuntu-16.04 --flavor m1.small \
  --security-group kubernetes --key-name tbritten \
  --nic net-id=1f9ce4ba-2203-4dc2-b411-c0b35ac588c8,v4-fixed-ip=10.240.0.10 \
  controller0
```

```
openstack server create --image ubuntu-16.04 --flavor m1.small \
  --security-group kubernetes --key-name tbritten \
  --nic net-id=1f9ce4ba-2203-4dc2-b411-c0b35ac588c8,v4-fixed-ip=10.240.0.11 \
  controller1
```

```
openstack server create --image ubuntu-16.04 --flavor m1.small \
  --security-group kubernetes --key-name tbritten \
  --nic net-id=1f9ce4ba-2203-4dc2-b411-c0b35ac588c8,v4-fixed-ip=10.240.0.12 \
  controller2
```

#### Kubernetes Workers

```
openstack server create --image ubuntu-16.04 --flavor m1.small \
  --security-group kubernetes --key-name tbritten \
  --nic net-id=1f9ce4ba-2203-4dc2-b411-c0b35ac588c8,v4-fixed-ip=10.240.0.20 \
  worker0
```

```
openstack server create --image ubuntu-16.04 --flavor m1.small \
  --security-group kubernetes --key-name tbritten \
  --nic net-id=1f9ce4ba-2203-4dc2-b411-c0b35ac588c8,v4-fixed-ip=10.240.0.21 \
  worker1
```

```
openstack server create --image ubuntu-16.04 --flavor m1.small \
  --security-group kubernetes --key-name tbritten \
  --nic net-id=1f9ce4ba-2203-4dc2-b411-c0b35ac588c8,v4-fixed-ip=10.240.0.22 \
  worker2
```

### Kubernetes Public Address

Attached a floating IP to the controller0 to allow for remote access:

```
openstack server add floating ip controller0 169.45.x.x
```

