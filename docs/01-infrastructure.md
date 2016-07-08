# Cloud Infrastructure Provisioning

Kubernetes can be installed just about anywhere physical or virtual machines can be run. In this lab we are going to focus on Google Cloud Platform (IaaS).

This lab will walk you through provisioning the compute instances required for running a H/A Kubernetes cluster. A total of 9 virtual machines will be created.

After completing this guide you should have the following compute instances:

```
gcloud compute instances list
```

````
NAME         ZONE           MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP      STATUS
controller0  us-central1-f  n1-standard-1               10.240.0.20  XXX.XXX.XXX.XXX  RUNNING
controller1  us-central1-f  n1-standard-1               10.240.0.21  XXX.XXX.XXX.XXX  RUNNING
controller2  us-central1-f  n1-standard-1               10.240.0.22  XXX.XXX.XXX.XXX  RUNNING
etcd0        us-central1-f  n1-standard-1               10.240.0.10  XXX.XXX.XXX.XXX  RUNNING
etcd1        us-central1-f  n1-standard-1               10.240.0.11  XXX.XXX.XXX.XXX  RUNNING
etcd2        us-central1-f  n1-standard-1               10.240.0.12  XXX.XXX.XXX.XXX  RUNNING
worker0      us-central1-f  n1-standard-1               10.240.0.30  XXX.XXX.XXX.XXX  RUNNING
worker1      us-central1-f  n1-standard-1               10.240.0.31  XXX.XXX.XXX.XXX  RUNNING
worker2      us-central1-f  n1-standard-1               10.240.0.32  XXX.XXX.XXX.XXX  RUNNING
````

> All machines will be provisioned with fixed private IP addresses to simplify the bootstrap process.

To make our Kubernetes control plane remotely accessible, a public IP address will be provisioned and assigned to a Load Balancer that will sit in front of the 3 Kubernetes controllers.

## Create a Custom Network

```
gcloud compute networks create kubernetes --mode custom
```

```
NAME        MODE    IPV4_RANGE  GATEWAY_IPV4
kubernetes  custom
```

```
gcloud compute networks subnets create kubernetes \
  --network kubernetes \
  --region us-central1 \
  --range 10.240.0.0/24
```

```
NAME        REGION       NETWORK     RANGE
kubernetes  us-central1  kubernetes  10.240.0.0/24
```

### Firewall Rules

```
gcloud compute firewall-rules create kubernetes-allow-icmp \
  --network kubernetes \
  --source-ranges 0.0.0.0/0 \
  --allow icmp
```

```
gcloud compute firewall-rules create kubernetes-allow-internal \
  --network kubernetes \
  --source-ranges 10.240.0.0/24 \
  --allow tcp:0-65535,udp:0-65535,icmp
```

```
gcloud compute firewall-rules create kubernetes-allow-rdp \
  --network kubernetes \
  --source-ranges 0.0.0.0/0 \
  --allow tcp:3389
```

```
gcloud compute firewall-rules create kubernetes-allow-ssh \
  --network kubernetes \
  --source-ranges 0.0.0.0/0 \
  --allow tcp:22
```

```
gcloud compute firewall-rules create kubernetes-allow-healthz \
  --network kubernetes \
  --allow tcp:8080 \
  --source-ranges 130.211.0.0/22
```

```
gcloud compute firewall-rules create kubernetes-allow-api-server \
  --network kubernetes \
  --source-ranges 0.0.0.0/0 \
  --allow tcp:6443
```


```
gcloud compute firewall-rules list --filter "network=kubernetes"
```

```
NAME                         NETWORK     SRC_RANGES      RULES                         SRC_TAGS  TARGET_TAGS
kubernetes-allow-api-server  kubernetes  0.0.0.0/0       tcp:6443
kubernetes-allow-healthz     kubernetes  130.211.0.0/22  tcp:8080
kubernetes-allow-icmp        kubernetes  0.0.0.0/0       icmp
kubernetes-allow-internal    kubernetes  10.240.0.0/24   tcp:0-65535,udp:0-65535,icmp
kubernetes-allow-rdp         kubernetes  0.0.0.0/0       tcp:3389
kubernetes-allow-ssh         kubernetes  0.0.0.0/0       tcp:22
```

## Create the Kubernetes Public IP Address

Create a public IP address that will be used by remote clients to connect to the Kubernetes control plane:

```
gcloud compute addresses create kubernetes
```

```
gcloud compute addresses list kubernetes
```
```
NAME        REGION       ADDRESS          STATUS
kubernetes  us-central1  XXX.XXX.XXX.XXX  RESERVED
```

## Provision Virtual Machines

All the VMs in this lab will be provisioned using Ubuntu 16.04 mainly because it runs a newish Linux Kernel that has good support for Docker.


### etcd

```
gcloud compute instances create etcd0 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --subnet kubernetes \
 --private-network-ip 10.240.0.10
```

```
gcloud compute instances create etcd1 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --subnet kubernetes \
 --private-network-ip 10.240.0.11
```

```
gcloud compute instances create etcd2 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --subnet kubernetes \
 --private-network-ip 10.240.0.12
```

### Kubernetes Controllers

```
gcloud compute instances create controller0 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --subnet kubernetes \
 --private-network-ip 10.240.0.20
```

```
gcloud compute instances create controller1 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --subnet kubernetes \
 --private-network-ip 10.240.0.21
```

```
gcloud compute instances create controller2 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --subnet kubernetes \
 --private-network-ip 10.240.0.22
```

### Kubernetes Workers

```
gcloud compute instances create worker0 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --subnet kubernetes \
 --private-network-ip 10.240.0.30
```

```
gcloud compute instances create worker1 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --subnet kubernetes \
 --private-network-ip 10.240.0.31
```

```
gcloud compute instances create worker2 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --subnet kubernetes \
 --private-network-ip 10.240.0.32
```
