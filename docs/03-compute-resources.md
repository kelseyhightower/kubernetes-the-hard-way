# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this lab you will provision the compute resources required for running a secure and highly available Kubernetes cluster across a single [compute zone](https://cloud.google.com/compute/docs/regions-zones/regions-zones).

> Ensure a default compute zone and region have been set as described in the [Prerequisites](01-prerequisites.md#set-a-default-compute-region-and-zone) lab.

> If you are using Azure, ensure that the azure cli has been set up and configured as described in the [Prerequisites](01-prerequisites.md#az-setup) lab.

## Networking

The Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) assumes a flat network in which containers and nodes can communicate with each other. In cases where this is not desired [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can limit how groups of containers are allowed to communicate with each other and external network endpoints.

> Setting up network policies is out of scope for this tutorial.

### Virtual Private Cloud Network

In this section a dedicated Virtual Private Cloud (VPC) network will be setup to host the Kubernetes cluster.

[Azure VPC documentation](https://learn.microsoft.com/en-us/azure/virtual-network/)

[GCloud VPC documentation](https://cloud.google.com/compute/docs/networks-and-firewalls#networks)

Create the `kubernetes-the-hard-way` custom VPC network:

```gcloud```
```
gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom
```
```az```
```
az network vnet create --name kubernetes-the-hard-way --address-prefix 10.240.0.0/24
```

A subnet must be provisioned with an IP address range large enough to assign a private IP address to each node in the Kubernetes cluster.

[Azure Subnet documentation](https://learn.microsoft.com/en-us/azure/virtual-network/network-overview#virtual-network-and-subnets)

[GCloud Subnet documentation](https://cloud.google.com/compute/docs/vpc/#vpc_networks_and_subnets)

Create the `kubernetes` subnet in the `kubernetes-the-hard-way` VPC network:

```gcloud```
```
gcloud compute networks subnets create kubernetes \
  --network kubernetes-the-hard-way \
  --range 10.240.0.0/24
```

```az```
```
az network vnet subnet create \
  --name kubernetes \
  --vnet-name kubernetes-the-hard-way \
  --address-prefixes 10.240.0.0/24
```

> The `10.240.0.0/24` IP address range can host up to 254 compute instances.

### Firewall Rules

> This section only applies to gcloud

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

> An [external load balancer](https://cloud.google.com/compute/docs/load-balancing/network/) will be used to expose the Kubernetes API Servers to remote clients.

List the firewall rules in the `kubernetes-the-hard-way` VPC network:

```
gcloud compute firewall-rules list --filter="network:kubernetes-the-hard-way"
```

> output

```
NAME                                    NETWORK                  DIRECTION  PRIORITY  ALLOW                 DENY  DISABLED
kubernetes-the-hard-way-allow-external  kubernetes-the-hard-way  INGRESS    1000      tcp:22,tcp:6443,icmp        False
kubernetes-the-hard-way-allow-internal  kubernetes-the-hard-way  INGRESS    1000      tcp,udp,icmp                Fals
```

### Network Security Group

> This section only applies to azure

Create a [Network Security Group](https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview) to allow https, ssh, and ICMP inbound traffic.

```
az network nsg create \
  --name kubernetes-the-hard-way-nsg

az network nsg rule create \
  --name kubernetes-the-hard-way-inbound-tcp \
  --nsg-name kubernetes-the-hard-way-nsg \
  --priority 100 \
  --access ALLOW \
  --source-address-prefixes 0.0.0.0/0 \
  --destination-port-ranges 22 6443 \
  --protocol Tcp \
  --direction Inbound

az network nsg rule create \
  --name kubernetes-the-hard-way-inbound-icmp \
  --nsg-name kubernetes-the-hard-way-nsg \
  --priority 200 \
  --access ALLOW \
  --source-address-prefixes 0.0.0.0/0 \
  --destination-port-ranges "*" \
  --protocol Icmp \
  --direction Inbound
```

### Kubernetes Public IP Address

Allocate a static IP address that will be attached to the external load balancer fronting the Kubernetes API Servers:

```gcloud```
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
NAME                     ADDRESS/RANGE   TYPE      PURPOSE  NETWORK  REGION    SUBNET  STATUS
kubernetes-the-hard-way  XX.XXX.XXX.XXX  EXTERNAL                    us-west1          RESERVED
```

```az```
```
az network public-ip create \
  --name kubernetes-the-hard-way \
  --allocation-method Static \
  --version IPv4
```

Verify the `kubernetes-the-hard-way` static IP address was created in your default Location:

```
az network public-ip list
```

> output

```
Name                     ResourceGroup     Location    Zones    Address          IdleTimeoutInMinutes    ProvisioningState
-----------------------  ----------------  ----------  -------  ---------------  ----------------------  -------------------
kubernetes-the-hard-way  k8s-the-hard-way  eastus               XXX.XXX.XXX.XXX  4                       Succeeded
```

## Compute Instances

The compute instances in this lab will be provisioned using [Ubuntu Server](https://www.ubuntu.com/server) 20.04, which has good support for the [containerd container runtime](https://github.com/containerd/containerd). Each compute instance will be provisioned with a fixed private IP address to simplify the Kubernetes bootstrapping process.

### Kubernetes Controllers

Create three compute instances which will host the Kubernetes control plane:

```gcloud```
```
for i in 0 1 2; do
  gcloud compute instances create controller-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-2004-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-standard-2 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,controller
done
```

```az```

To start, we will create an ssh keypair which will be used to authenticate with the VMs. This keypair will be stored in `$HOME/.ssh/k8sthehardway[.pub]` and also uploaded to azure with the name `k8sthehardway`

```
mkdir -p $HOME/.ssh
ssh-keygen -f $HOME/.ssh/k8sthehardway
az sshkey create --name k8sthehardway --public-key "@$HOME/.ssh/k8sthehardway.pub"
```

```
for i in 0 1 2; do
  az vm create \
    --name controller-${i} \
    --nsg kubernetes-the-hard-way-nsg \
    --private-ip-address 10.240.0.1${i} \
    --authentication-type ssh \
    --image Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest \
    --admin-username azureuser \
    --ssh-key-name k8sthehardway \
    --priority Regular \
    --subnet kubernetes \
    --vnet-name kubernetes-the-hard-way \
    --size Standard_DS1_v2 \
    --tags public-ip=$(az network public-ip show --name kubernetes-the-hard-way --query ipAddress -o tsv)
done
```

> The azure VMs will have the username `azureuser`. The only method of authentication available will be public key, with the key in question stored at $HOME/.ssh/k8sthehardway

> :warning:WARNING:warning:: These VMs are accessible on the internet. Adding proper security beyond public key authentication is beyond the scope of this tutorial, so be very sure clean them up when you are done

### Kubernetes Workers

Each worker instance requires a pod subnet allocation from the Kubernetes cluster CIDR range. The pod subnet allocation will be used to configure container networking in a later exercise. The `pod-cidr` instance metadata will be used to expose pod subnet allocations to compute instances at runtime.

> The Kubernetes cluster CIDR range is defined by the Controller Manager's `--cluster-cidr` flag. In this tutorial the cluster CIDR range will be set to `10.200.0.0/16`, which supports 254 subnets.

Create three compute instances which will host the Kubernetes worker nodes:

```gcloud```
```
for i in 0 1 2; do
  gcloud compute instances create worker-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-2004-lts \
    --image-project ubuntu-os-cloud \
    --machine-type e2-standard-2 \
    --metadata pod-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,worker
done
```

```az```
```
for i in 0 1 2; do
  az vm create \
    --name worker-${i} \
    --nsg kubernetes-the-hard-way-nsg \
    --private-ip-address 10.240.0.2${i} \
    --authentication-type ssh \
    --image Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest \
    --admin-username azureuser \
    --ssh-key-name k8sthehardway \
    --priority Regular \
    --subnet kubernetes \
    --vnet-name kubernetes-the-hard-way \
    --size Standard_DS1_v2 \
    --tags pod-cidr=10.200.${i}.0/24
done
```

> The azure VMs will have the username `azureuser`. The only method of authentication available will be public key, with the key in question stored at $HOME/.ssh/k8sthehardway

> :warning:WARNING:warning:: These VMs are accessible on the internet. Adding proper security beyond public key authentication is beyond the scope of this tutorial, so be very sure clean them up when you are done

### Verification

List the compute instances in your default compute zone:

```gcloud```
```
gcloud compute instances list --filter="tags.items=kubernetes-the-hard-way"
```

> output

```
NAME          ZONE        MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP    STATUS
controller-0  us-west1-c  e2-standard-2               10.240.0.10  XX.XX.XX.XXX   RUNNING
controller-1  us-west1-c  e2-standard-2               10.240.0.11  XX.XXX.XXX.XX  RUNNING
controller-2  us-west1-c  e2-standard-2               10.240.0.12  XX.XXX.XX.XXX  RUNNING
worker-0      us-west1-c  e2-standard-2               10.240.0.20  XX.XX.XXX.XXX  RUNNING
worker-1      us-west1-c  e2-standard-2               10.240.0.21  XX.XX.XX.XXX   RUNNING
worker-2      us-west1-c  e2-standard-2               10.240.0.22  XX.XXX.XX.XX   RUNNING
```

```az```
```
az vm list
```

> output

```
Name          ResourceGroup     Location    Zones
------------  ----------------  ----------  -------
controller-0  k8s-the-hard-way  eastus
controller-1  k8s-the-hard-way  eastus
controller-2  k8s-the-hard-way  eastus
worker-0      k8s-the-hard-way  eastus
worker-1      k8s-the-hard-way  eastus
worker-2      k8s-the-hard-way  eastus
```

## Configuring SSH Access (GCloud)

SSH will be used to configure the controller and worker instances. When connecting to compute instances for the first time SSH keys will be generated for you and stored in the project or instance metadata as described in the [connecting to instances](https://cloud.google.com/compute/docs/instances/connecting-to-instance) documentation.

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
Welcome to Ubuntu 20.04.2 LTS (GNU/Linux 5.4.0-1042-gcp x86_64)
...
```

Type `exit` at the prompt to exit the `controller-0` compute instance:

```
$USER@controller-0:~$ exit
```
> output

```
logout
Connection to XX.XX.XX.XXX closed
```

## Configuring SSH Access (Azure)

The VMs have been provisioned with the `k8sthehardway` keypair to allow the `azureuser` to log in. You can ssh into them via either the `az ssh` command or via normal ssh. The advantage of going through the azure cli is you don't need to remember the ip address or location of the keypair to connect, and the command is not as verbose. The advantage of plain ssh is this is more familiar to most users.

### az ssh

Run the following command to connect to `controller-0` (replace `controller-0` with the desired VM to connect to others). Note that the first time you use `az ssh` you will be prompted to install the `ssh` extension to the azure CLI.

```
az ssh vm --name controller-0 --local-user azureuser
```

### ssh

Run the following command to connect to the `controller-0` VM instance via plain ssh

```
ssh -i $HOME/.ssh/k8sthehardway azureuser@$(az vm show -d --name controller-0 --query "publicIps" -o tsv)
```

Next: [Provisioning a CA and Generating TLS Certificates](04-certificate-authority.md)
