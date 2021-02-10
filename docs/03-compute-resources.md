# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this lab you will provision the compute resources required for running a secure and highly available Kubernetes cluster across a single [compute zone](https://cloud.google.com/compute/docs/regions-zones/regions-zones).

> Ensure a default compute zone and region have been set as described in the [Prerequisites](01-prerequisites.md#set-a-default-compute-region-and-zone) lab.

## Networking

The Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) assumes a flat network in which containers and nodes can communicate with each other. In cases where this is not desired [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can limit how groups of containers are allowed to communicate with each other and external network endpoints.

> Setting up network policies is out of scope for this tutorial.

### Virtual Cloud Network

In this section a dedicated [Virtual Cloud Network](https://www.oracle.com/cloud/networking/virtual-cloud-network/) (VCN) network will be setup to host the Kubernetes cluster.

Create the `kubernetes-the-hard-way` custom VCN:

```
VCN_ID=$(oci network vcn create --display-name kubernetes-the-hard-way --dns-label vcn --cidr-block \
  10.240.0.0/24 | jq -r .data.id)
```

A [subnet](https://docs.oracle.com/en-us/iaas/Content/Network/Tasks/managingVCNs_topic-Overview_of_VCNs_and_Subnets.htm#Overview) must be provisioned with an IP address range large enough to assign a private IP address to each node in the Kubernetes cluster.

Create the `kubernetes` subnet in the `kubernetes-the-hard-way` VCN, along with a Route Table and Internet Gateway allowing traffic to the internet.

```
INTERNET_GATEWAY_ID=$(oci network internet-gateway create --display-name kubernetes-the-hard-way \ 
  --vcn-id $VCN_ID --is-enabled true | jq -r .data.id)
ROUTE_TABLE_ID=$(oci network route-table create --display-name kubernetes-the-hard-way --vcn-id $VCN_ID \
  --route-rules  "[{\"cidrBlock\":\"0.0.0.0/0\",\"networkEntityId\":\"$INTERNET_GATEWAY_ID\"}]" \
   | jq -r .data.id)
SUBNET_ID=$(oci network subnet create --display-name kubernetes --vcn-id $VCN_ID --dns-label subnet \
  --cidr-block 10.240.0.0/24 --route-table-id $ROUTE_TABLE_ID | jq -r .data.id)
```

> The `10.240.0.0/24` IP address range can host up to 254 compute instances.

:warning: **Note**: For simplicity and to stay close to the original kubernetes-the-hard-way, we will be using a single subnet, shared between the Kubernetes worker nodes, controller plane nodes, and LoadBalancer.  A production-caliber setup would consist of at least:
- A dedicated public subnet for the public LoadBalancer.
- A dedicated private subnet for controller plan nodes.
- A dedicated private subnet for worker nodes.  This setup would not allow NodePort access to services.

## Compute Instances

The compute instances in this lab will be provisioned using [Ubuntu Server](https://www.ubuntu.com/server) 20.04, which has good support for the [containerd container runtime](https://github.com/containerd/containerd). Each compute instance will be provisioned with a fixed private IP address to simplify the Kubernetes bootstrapping process.

:warning: **Note**: For simplicity in this tutorial, we will be accessing controller and worker nodes over SSH, using public addresses.  A production-caliber setup would instead run controller and worker nodes in _private_ subnets, with any direct SSH access done via [Bastions](https://docs.oracle.com/en-us/iaas/Content/Resources/Assets/whitepapers/bastion-hosts.pdf) when required. 

### Create SSH Keys

Generate an RSA key pair, which we'll use for SSH access to our compute nodes:

```
ssh-keygen -b 2048 -t rsa -f kubernetes_ssh_rsa
```

Enter a passphrase at the prompt to continue:
```
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
```

Results:
```
kubernetes_ssh_rsa
kubernetes_ssh_rsa.pub
```

### Kubernetes Controllers

Create three compute instances which will host the Kubernetes control plane:

```
IMAGE_ID=$(oci compute image list --operating-system "Canonical Ubuntu" --operating-system-version \
  "20.04" | jq -r .data[0].id)  
NUM_ADS=$(oci iam availability-domain list | jq -r .data | jq length)  
for i in 0 1 2; do
  # Rudimentary distributing of nodes across Availability Domains and Fault Domains
  AD_NAME=$(oci iam availability-domain list | jq -r .data[$((i % NUM_ADS))].name)
  NUM_FDS=$(oci iam fault-domain list --availability-domain $AD_NAME | jq -r .data | jq length)
  FD_NAME=$(oci iam fault-domain list --availability-domain $AD_NAME | jq -r .data[$((i % NUM_FDS))].name)  
  
  oci compute instance launch --display-name controller-${i} --assign-public-ip true \
    --subnet-id $SUBNET_ID --shape VM.Standard.E3.Flex --availability-domain $AD_NAME \
    --fault-domain $FD_NAME --image-id $IMAGE_ID --shape-config '{"memoryInGBs": 8.0, "ocpus": 2.0}' \
    --private-ip 10.240.0.1${i} \
    --freeform-tags '{"project": "kubernetes-the-hard-way","role":"controller"}' \
     --metadata "{\"ssh_authorized_keys\":\"$(cat kubernetes_ssh_rsa.pub)\"}"
done
```

### Kubernetes Workers

Each worker instance requires a pod subnet allocation from the Kubernetes cluster CIDR range. The pod subnet allocation will be used to configure container networking in a later exercise. The `pod-cidr` instance metadata will be used to expose pod subnet allocations to compute instances at runtime.

> The Kubernetes cluster CIDR range is defined by the Controller Manager's `--cluster-cidr` flag. In this tutorial the cluster CIDR range will be set to `10.200.0.0/16`, which supports 254 subnets.

Create three compute instances which will host the Kubernetes worker nodes:

```
IMAGE_ID=$(oci compute image list --operating-system "Canonical Ubuntu" --operating-system-version \
  "20.04" | jq -r .data[0].id)  
NUM_ADS=$(oci iam availability-domain list | jq -r .data | jq length)
for i in 0 1 2; do
  # Rudimentary distributing of nodes across Availability Domains and Fault Domains
  AD_NAME=$(oci iam availability-domain list | jq -r .data[$((i % NUM_ADS))].name)
  NUM_FDS=$(oci iam fault-domain list --availability-domain $AD_NAME | jq -r .data | jq length)
  FD_NAME=$(oci iam fault-domain list --availability-domain $AD_NAME | jq -r .data[$((i % NUM_FDS))].name)

  oci compute instance launch --display-name worker-${i} --assign-public-ip true \
    --subnet-id $SUBNET_ID --shape VM.Standard.E3.Flex --availability-domain $AD_NAME \
    --fault-domain $FD_NAME --image-id $IMAGE_ID --shape-config '{"memoryInGBs": 8.0, "ocpus": 2.0}' \
    --private-ip 10.240.0.2${i} \
    --freeform-tags '{"project": "kubernetes-the-hard-way","role":"worker"}' \
    --metadata "{\"ssh_authorized_keys\":\"$(cat kubernetes_ssh_rsa.pub)\",\"pod-cidr\":\"10.200.${i}.0/24\"}" \
    --skip-source-dest-check true
done
```

### Verification

List the compute instances in our compartment:

```
oci compute instance list --sort-by DISPLAYNAME --lifecycle-state RUNNING --all | jq -r .data[] \
  | jq '{"display-name","lifecycle-state"}'
```

> output

```
{
  "display-name": "controller-0",
  "lifecycle-state": "RUNNING"
}
{
  "display-name": "controller-1",
  "lifecycle-state": "RUNNING"
}
{
  "display-name": "controller-2",
  "lifecycle-state": "RUNNING"
}
{
  "display-name": "worker-0",
  "lifecycle-state": "RUNNING"
}
{
  "display-name": "worker-1",
  "lifecycle-state": "RUNNING"
}
{
  "display-name": "worker-2",
  "lifecycle-state": "RUNNING"
}
```

Rerun the above command until all of the compute instances we created are listed above as "Running".

## Verifying SSH Access

Our subnet was created with a default Security List that allows public SSH access, so we can verify at this point that SSH is working:

```
oci-ssh controller-0
```

The first time SSHing into a node, you'll see something like the following, at which point enter "yes":
```
The authenticity of host 'XX.XX.XX.XXX (XX.XX.XX.XXX )' can't be established.
ECDSA key fingerprint is SHA256:xxxxxxxxxxxxxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxx.
Are you sure you want to continue connecting (yes/no/[fingerprint])? 
```

```
Welcome to Ubuntu 20.04.1 LTS (GNU/Linux 5.4.0-1029-oracle x86_64)
...
```

Type `exit` at the prompt to exit the `controller-0` compute instance:

```
ubuntu@controller-0:~$ exit
```
> output

```
logout
Connection to XX.XX.XX.XXX closed
```

### Security Lists

For use in later steps of the tutorial, we'll create Security Lists to allow:
- Intra-VCN communication between worker and controller nodes.
- Public access to the NodePort range.
- Public access to the LoadBalancer port.

```
{
  INTRA_VCN_SECURITY_LIST_ID=$(oci network security-list create --display-name intra-vcn \
    --vcn-id $VCN_ID  --ingress-security-rules '[
  {
    "icmp-options": null,
    "is-stateless": true,
    "protocol": "all",
    "source": "10.240.0.0/24",
    "source-type": "CIDR_BLOCK",
    "tcp-options": null,
    "udp-options": null
  }]' --egress-security-rules '[]' | jq -r .data.id)
  
  WORKER_SECURITY_LIST_ID=$(oci network security-list create --display-name worker \
    --vcn-id $VCN_ID --ingress-security-rules '[
  {
    "icmp-options": null,
    "is-stateless": false,
    "protocol": "6",
    "source": "0.0.0.0/0",
    "source-type": "CIDR_BLOCK",
    "tcp-options": {
      "destination-port-range": {
        "max": 32767,
        "min": 30000
      },
      "source-port-range": null
    },
    "udp-options": null
  }]' --egress-security-rules '[]' | jq -r .data.id)
  
  LB_SECURITY_LIST_ID=$(oci network security-list create --display-name load-balancer \
    --vcn-id $VCN_ID  --ingress-security-rules '[
  {
    "icmp-options": null,
    "is-stateless": false,
    "protocol": "6",
    "source": "0.0.0.0/0",
    "source-type": "CIDR_BLOCK",
    "tcp-options": {
      "destination-port-range": {
        "max": 6443,
        "min": 6443
      },
      "source-port-range": null
    },
    "udp-options": null
  }]' --egress-security-rules '[]' | jq -r .data.id)
}
```

We'll add these Security Lists to our subnet:
```
{
  DEFAULT_SECURITY_LIST_ID=$(oci network security-list list --display-name \
    "Default Security List for kubernetes-the-hard-way" | jq -r .data[0].id)
  oci network subnet update --subnet-id $SUBNET_ID --force --security-list-ids \
   "[\"$DEFAULT_SECURITY_LIST_ID\",\"$INTRA_VCN_SECURITY_LIST_ID\",\"$WORKER_SECURITY_LIST_ID\",\"$LB_SECURITY_LIST_ID\"]"
}
```

### Firewall Rules

And similarly, we'll open up the firewall of the worker and controller nodes to allow intra-VCN traffic.

```
for instance in controller-0 controller-1 controller-2; do
  oci-ssh ${instance} "sudo ufw allow from 10.240.0.0/24;sudo iptables -A INPUT -i ens3 -s 10.240.0.0/24 -j ACCEPT;sudo iptables -F"
done
for instance in worker-0 worker-1 worker-2; do
  oci-ssh ${instance} "sudo ufw allow from 10.240.0.0/24;sudo iptables -A INPUT -i ens3 -s 10.240.0.0/24 -j ACCEPT;sudo iptables -F"
done
```

### Provision a Network Load Balancer

> An [OCI Load Balancer](https://docs.oracle.com/en-us/iaas/Content/Balance/Concepts/balanceoverview.htm) will be used to expose the Kubernetes API Servers to remote clients.

Create the Load Balancer:

```
LOADBALANCER_ID=$(oci lb load-balancer create --display-name  kubernetes-the-hard-way \
  --shape-name 100Mbps --wait-for-state SUCCEEDED --subnet-ids "[\"$SUBNET_ID\"]" | jq -r .data.id)
```

Create a Backend Set, with Backends for the our 3 controller nodes:
```
{
cat > backends.json <<EOF
[
    {
        "ipAddress": "10.240.0.10",
        "port": 6443,
        "weight": 1
    },
    {
        "ipAddress": "10.240.0.11",
        "port": 6443,
        "weight": 1
    },
    {
        "ipAddress": "10.240.0.12",
        "port": 6443,
        "weight": 1
    }            
]
EOF
oci lb backend-set create --name controller-backend-set --load-balancer-id $LOADBALANCER_ID --backends file://backends.json \
  --health-checker-interval-in-ms 10000 --health-checker-port 8888 --health-checker-protocol HTTP \
  --health-checker-retries 3 --health-checker-return-code 200 --health-checker-timeout-in-ms 3000 \
  --health-checker-url-path "/healthz" --policy "ROUND_ROBIN" --wait-for-state SUCCEEDED 
  
oci lb listener create --name controller-listener --default-backend-set-name controller-backend-set \
  --port 6443 --protocol TCP --load-balancer-id $LOADBALANCER_ID  --wait-for-state SUCCEEDED
}
```

At this point, the Load Balancer will be shown as in a "Critical" state - that's ok.  This will be case until we configure the API server on the controller nodes in subsequent steps.

Next: [Provisioning a CA and Generating TLS Certificates](04-certificate-authority.md)
