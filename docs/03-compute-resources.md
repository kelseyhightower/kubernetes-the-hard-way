# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this lab you will provision the compute resources required for running a secure and highly available Kubernetes cluster across a single [compute zone](https://cloud.google.com/compute/docs/regions-zones).

> Ensure a default compute zone and region have been set as described in the [Prerequisites](./01-prerequisites.md#set-a-default-compute-region-and-zone) lab.

## Networking

The Kubernetes [network model](https://kubernetes.io/docs/concepts/services-networking/#the-kubernetes-network-model) assumes a flat network in which containers and nodes can communicate with each other. In cases where this is not desired [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can limit how groups of containers are allowed to communicate with each other and external network endpoints.

> Setting up network policies is out of scope for this tutorial.

### Virtual Private Cloud (VPC) Network

In this section a dedicated [VPC network](https://cloud.google.com/vpc/docs/vpc) will be setup to host the Kubernetes cluster.

Create the `kubernetes-the-hard-way` custom VPC network:

```
gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom
```

A [subnet](https://cloud.google.com/vpc/docs/vpc#vpc_networks_and_subnets) must be provisioned with an IP address range large enough to assign a private IP address to each node in the Kubernetes cluster.

Create the `kubernetes` subnet in the `kubernetes-the-hard-way` VPC network:

```
gcloud compute networks subnets create kubernetes \
  --network kubernetes-the-hard-way \
  --range 10.240.0.0/24
```

> The `10.240.0.0/24` IP address range can host up to 254 compute instances.

### Firewall Rules

Create a firewall rule that allows internal communication across all protocols:

```
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
  --allow tcp,udp,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 10.240.0.0/24,10.200.0.0/16
```

Create a firewall rule that allows external SSH, ICMP, and HTTPS:

```
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network kubernetes-the-hard-way \
  --source-ranges 0.0.0.0/0
```

> An [external load balancer](https://cloud.google.com/load-balancing/docs/network) will be used to expose the Kubernetes API Servers to remote clients.

List the firewall rules in the `kubernetes-the-hard-way` VPC network:

```
gcloud compute firewall-rules list --filter network:kubernetes-the-hard-way
```

> output

```
NAME                                    NETWORK                  DIRECTION  PRIORITY  ALLOW                 DENY  DISABLED
kubernetes-the-hard-way-allow-external  kubernetes-the-hard-way  INGRESS    1000      tcp:22,tcp:6443,icmp        False
kubernetes-the-hard-way-allow-internal  kubernetes-the-hard-way  INGRESS    1000      tcp,udp,icmp                False
```

### Kubernetes Public IP Address

Allocate a static IP address that will be attached to the external load balancer fronting the Kubernetes API Servers:

```
gcloud compute addresses create kubernetes-the-hard-way
```

Verify the `kubernetes-the-hard-way` static IP address was created in your default compute region:

```
gcloud compute addresses list --filter name=kubernetes-the-hard-way
```

> output

```
NAME                     ADDRESS/RANGE   TYPE      PURPOSE  NETWORK  REGION    SUBNET  STATUS
kubernetes-the-hard-way  XX.XXX.XXX.XXX  EXTERNAL                    us-east1          RESERVED
```

## Compute Instances

The compute instances in this lab will be provisioned using [Ubuntu Server 22.04 LTS](https://ubuntu.com/server), which has good support for the [containerd](https://github.com/containerd/containerd) container runtime. Each compute instance will be provisioned with a fixed private IP address to simplify the Kubernetes bootstrapping process.

### Kubernetes Controllers

Create three compute instances which will host the Kubernetes control plane:

```
for i in 0 1 2; do
  gcloud compute instances create "controller-${i}" \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-2204-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-standard-2 \
    --private-network-ip "10.240.0.1${i}" \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,controller
done
```

### Kubernetes Workers

Each worker instance requires a pod subnet allocation from the Kubernetes cluster CIDR range. The pod subnet allocation will be used to configure container networking in a later exercise. The `pod-cidr` instance metadata will be used to expose pod subnet allocations to compute instances at runtime.

> The Kubernetes cluster CIDR range is defined by the Controller Manager's `--cluster-cidr` flag. In this tutorial the cluster CIDR range will be set to `10.200.0.0/16`, which supports 254 subnets.

Create three compute instances which will host the Kubernetes worker nodes:

```
for i in 0 1 2; do
  gcloud compute instances create "worker-${i}" \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-2204-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-standard-2 \
    --metadata "pod-cidr=10.200.${i}.0/24" \
    --private-network-ip "10.240.0.2${i}" \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,worker
done
```

### Verification

List the compute instances in your default compute zone:

```
gcloud compute instances list --filter tags.items=kubernetes-the-hard-way
```

> output

```
NAME          ZONE        MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
controller-0  us-east1-d  e2-standard-2               10.240.0.10  XX.XXX.XX.XXX   RUNNING
controller-1  us-east1-d  e2-standard-2               10.240.0.11  XX.XXX.XX.XXX   RUNNING
controller-2  us-east1-d  e2-standard-2               10.240.0.12  XX.XXX.XX.XX    RUNNING
worker-0      us-east1-d  e2-standard-2               10.240.0.20  XX.XX.XX.XXX    RUNNING
worker-1      us-east1-d  e2-standard-2               10.240.0.21  XX.XXX.XXX.XXX  RUNNING
worker-2      us-east1-d  e2-standard-2               10.240.0.22  XX.XXX.XXX.XX   RUNNING
```

## Configuring SSH Access

SSH will be used to configure the controller and worker instances. When connecting to compute instances for the first time SSH keys will be generated for you and stored in the project or instance metadata as described in the [connecting to Linux VMs](https://cloud.google.com/compute/docs/connect/standard-ssh) documentation.

Test SSH access to the `controller-0` compute instances:

```
gcloud compute ssh controller-0
```

If this is your first time connecting to a compute instance SSH keys will be generated for you. Enter a passphrase at the prompt to continue:

```
WARNING: The private SSH key file for gcloud does not exist.
WARNING: The public SSH key file for gcloud does not exist.
WARNING: You do not have an SSH key for gcloud.
WARNING: SSH keygen will be executed to generate a key.
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
```

At this point the generated SSH keys will be uploaded and stored in your project:

```
Your identification has been saved in "/home/${USER}/.ssh/google_compute_engine"
Your public key has been saved in "/home/${USER}/.ssh/google_compute_engine.pub"
The key fingerprint is:
SHA256:OvopaMrkGOrbB0u2JMdwDvH6wGQBieKUC+XRAAm07RI "${USER}@${HOSTNAME}"
The key's randomart image is:
+---[RSA 3072]----+
|O*=o             |
|**o..            |
|=E*.             |
| Boo             |
|+.B.    S        |
| =.O   .         |
|..O.+ o          |
|*.++.o o         |
|=B..ooo          |
+----[SHA256]-----+
Updating project ssh metadata...Updated ["https://www.googleapis.com/compute/v1/projects/${PROJECT_ID}"].
Updating project ssh metadata...done.
Waiting for SSH key to propagate.
```

After the SSH keys have been updated you'll be logged into the `controller-0` instance:

```
Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.19.0-1027-gcp x86_64)
...
```

Type `exit` at the prompt to exit the `controller-0` compute instance:

```
exit
```

> output

```
logout
Connection to XX.XXX.XX.XXX closed.
```

Next: [Provisioning a CA and Generating TLS Certificates](./04-certificate-authority.md)
