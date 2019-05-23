# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this lab you will provision the compute resources required for running a secure and highly available Kubernetes cluster.

> Ensure a default region has been set as described in the [Prerequisites](01-prerequisites.md#set-a-default-compute-region-and-zone) lab.

## Resource Group
In Azure, compute resources are tied to a resource group, let's create one for the tutorial:

```
az group create --name kubernetes-the-hard-way --location westus2
```

## Networking

The Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) assumes a flat network in which containers and nodes can communicate with each other. In cases where this is not desired [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can limit how groups of containers are allowed to communicate with each other and external network endpoints.

> Setting up network policies is out of scope for this tutorial.

### Virtual Private Cloud Network

In this section a dedicated [Virtual Network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) (VNET) network will be setup to host the Kubernetes cluster. A subnet must be provisioned with an IP address range large enough to assign a private IP address to each node in the Kubernetes cluster.

Create the `kubernetes-the-hard-way` custom VNET network and subnet:

```
az network vnet create \
  --resource-group kubernetes-the-hard-way \
  --name kubernetes-the-hard-way-vnet \
  --address-prefixes 10.240.0.0/16 \
  --subnet-name kubernetes-the-hard-way-subnet \
  --subnet-prefixes 10.240.0.0/24
```

> The `10.240.0.0/24` IP address range can host up to 254 compute instances.

### Security Group

Create a security group that allows internal communication across all protocols:

```
az network nsg create --resource-group kubernetes-the-hard-way --name kubernetes-the-hard-way-nsg
```

Create a firewall rule that allows external SSH, and HTTPS:

```
az network nsg rule create \
  --resource-group kubernetes-the-hard-way \
  --nsg-name kubernetes-the-hard-way-nsg \
  --name K8s \
  --access Allow \
  --protocol Tcp \
  --direction Inbound \
  --priority 100 \
  --source-address-prefix Internet \
  --source-port-range "*" \
  --destination-port-ranges 22 6443
```

> An [external load balancer](https://azure.microsoft.com/en-us/services/load-balancer/) will be used to expose the Kubernetes API Servers to remote clients.

List the security group rule in the `kubernetes-the-hard-way` resource group:

```
az network nsg rule show --resource-group kubernetes-the-hard-way --name K8s --nsg-name kubernetes-the-hard-way-nsg
```

> output

```json
{
  "access": "Allow",
  "description": null,
  "destinationAddressPrefix": "*",
  "destinationAddressPrefixes": [],
  "destinationApplicationSecurityGroups": null,
  "destinationPortRange": null,
  "destinationPortRanges": [
    "22",
    "6443"
  ],
  "direction": "Inbound",
  "etag": "W/\"XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX\"",
  "id": "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/kubernetes-the-hard-way/providers/Microsoft.Network/networkSecurityGroups/kubernetes-the-hard-way-nsg/securityRules/K8s",
  "name": "K8s",
  "priority": 100,
  "protocol": "Tcp",
  "provisioningState": "Succeeded",
  "resourceGroup": "kubernetes-the-hard-way",
  "sourceAddressPrefix": "Internet",
  "sourceAddressPrefixes": [],
  "sourceApplicationSecurityGroups": null,
  "sourcePortRange": "*",
  "sourcePortRanges": [],
  "type": "Microsoft.Network/networkSecurityGroups/securityRules"
}
```

### Kubernetes Public IP Address

Allocate a static IP address that will be attached to the external load balancer fronting the Kubernetes API Servers:

```
az network public-ip create \
  --name kubernetes-the-hard-way-ip \
  --resource-group kubernetes-the-hard-way \
  --allocation-method Static
```

Verify the `kubernetes-the-hard-way` static IP address was created in your default compute region:

```
az network public-ip show --resource-group kubernetes-the-hard-way --name kubernetes-the-hard-way-ip
```

> output

```json
{
  "ddosSettings": null,
  "dnsSettings": null,
  "etag": "W/\"XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX\"",
  "id": "/subscriptions/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/resourceGroups/kubernetes-the-hard-way/providers/Microsoft.Network/publicIPAddresses/kubernetes-the-hard-way-ip",
  "idleTimeoutInMinutes": 4,
  "ipAddress": "XX.XXX.XXX.XX",
  "ipConfiguration": null,
  "ipTags": [],
  "location": "westus2",
  "name": "kubernetes-the-hard-way-ip",
  "provisioningState": "Succeeded",
  "publicIpAddressVersion": "IPv4",
  "publicIpAllocationMethod": "Static",
  "publicIpPrefix": null,
  "resourceGroup": "kubernetes-the-hard-way",
  "resourceGuid": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "sku": {
    "name": "Basic",
    "tier": "Regional"
  },
  "tags": null,
  "type": "Microsoft.Network/publicIPAddresses",
  "zones": null
}
```

## Compute Instances

The compute instances in this lab will be provisioned using [Ubuntu Server](https://www.ubuntu.com/server) 18.04, which has good support for the [containerd container runtime](https://github.com/containerd/containerd). Each compute instance will be provisioned with a fixed private IP address to simplify the Kubernetes bootstrapping process.

### Kubernetes Controllers

Create three compute instances which will host the Kubernetes control plane:

```
for i in 0 1 2; do
  az vm create \
    --name controller-${i} \
    --resource-group kubernetes-the-hard-way
    --no-wait \
    --vent-name kubernetes-the-hard-way-vnet
    --subnet kubernetes-the-hard-way-subnet
    --nsg kubernetes-the-hard-way-nsg
    --private-ip-address 10.240.0.1${i}
    --public-ip-address-allocation Static
    --image Canonical:UbuntuServer:18.04-LTS:latest
    --admin-username azureuser
    --generate-ssh-keys
    --size Standard_B2s
    --data-disk-sizes-gb 200
done
```

### Kubernetes Workers

Each worker instance requires a pod subnet allocation from the Kubernetes cluster CIDR range. The pod subnet allocation will be used to configure container networking in a later exercise. The `pod-cidr` instance metadata will be used to expose pod subnet allocations to compute instances at runtime.

> The Kubernetes cluster CIDR range is defined by the Controller Manager's `--cluster-cidr` flag. In this tutorial the cluster CIDR range will be set to `10.200.0.0/16`, which supports 254 subnets.

Create three compute instances which will host the Kubernetes worker nodes:

```
for i in 0 1 2; do
  az vm create \
    --name worker-${i} \
    --resource-group kubernetes-the-hard-way
    --no-wait \
    --vent-name kubernetes-the-hard-way-vnet
    --subnet kubernetes-the-hard-way-subnet
    --nsg kubernetes-the-hard-way-nsg
    --private-ip-address 10.240.0.2${i}
    --public-ip-address-allocation Static
    --image Canonical:UbuntuServer:18.04-LTS:latest
    --admin-username azureuser
    --generate-ssh-keys
    --size Standard_B2s
    --data-disk-sizes-gb 200
done
```

### Verification

List the compute instances in your default compute zone:

```
az vm list --resource-group kubernetes-the-hard-way --output table
```

> output

```
Name          ResourceGroup            Location    Zones
------------  -----------------------  ----------  -------
controller-0  kubernetes-the-hard-way  westus2
controller-1  kubernetes-the-hard-way  westus2
controller-2  kubernetes-the-hard-way  westus2
worker-0      kubernetes-the-hard-way  westus2
worker-1      kubernetes-the-hard-way  westus2
worker-2      kubernetes-the-hard-way  westus2
```

## Configuring SSH Access

SSH will be used to configure the controller and worker instances. When building the compute instances, if you don't currently have an SSH keypair, one will be generated for you and stored in  your ~/.ssh directory

Test SSH access to the `controller-0` compute instances using the VMs public IP address (this can be found by list your VMs with the CLI, or by looking at the VM in the Azure portal):

```
ssh azureuser@{controller-0-Public-IP}
```

```
Welcome to Ubuntu 18.04 LTS (GNU/Linux 4.15.0-1006-gcp x86_64)

...

Last login: Sun May 13 14:34:27 2018 from XX.XXX.XXX.XX
```

Type `exit` at the prompt to exit the `controller-0` compute instance:

```
$azureuser@controller-0:~$ exit
```
> output

```
logout
Connection to XX.XXX.XXX.XXX closed
```

Next: [Provisioning a CA and Generating TLS Certificates](04-certificate-authority.md)
