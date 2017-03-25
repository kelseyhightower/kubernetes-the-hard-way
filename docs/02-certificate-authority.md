# Setting up a Certificate Authority and TLS Cert Generation

In this lab you will setup the necessary PKI infrastructure to secure the Kubernetes components. This lab will leverage CloudFlare's PKI toolkit, [cfssl](https://github.com/cloudflare/cfssl), to bootstrap a Certificate Authority and generate TLS certificates.

In this lab you will generate a set of TLS certificates that can be used to secure the following Kubernetes components:

* etcd
* kube-apiserver
* kubelet
* kube-proxy

After completing this lab you should have the following TLS keys and certificates:

```
admin.pem
admin-key.pem
ca-key.pem
ca.pem
kubernetes-key.pem
kubernetes.pem
kube-proxy.pem
kube-proxy-key.pem
```


## Install CFSSL

This lab requires the `cfssl` and `cfssljson` binaries. Download them from the [cfssl repository](https://pkg.cfssl.org).

### OS X

```
wget https://pkg.cfssl.org/R1.2/cfssl_darwin-amd64
chmod +x cfssl_darwin-amd64
sudo mv cfssl_darwin-amd64 /usr/local/bin/cfssl
```

```
wget https://pkg.cfssl.org/R1.2/cfssljson_darwin-amd64
chmod +x cfssljson_darwin-amd64
sudo mv cfssljson_darwin-amd64 /usr/local/bin/cfssljson
```

### Linux

```
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
chmod +x cfssl_linux-amd64
sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
```

```
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x cfssljson_linux-amd64
sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
```

## Set up a Certificate Authority

Create a CA configuration file:

```
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF
```

Create a CA certificate signing request:


```
cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF
```

Generate the CA certificate and private key:

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

Results:

```
ca-key.pem
ca.pem
```

## Generate client and server TLS certificates

In this section we will generate TLS certificates for all each Kubernetes component and a client certificate for an admin client.


### Create the Admin client certificate

Create the admin client certificate signing request:

```
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "Cluster",
      "ST": "Oregon"
    }
  ]
}
EOF
```

Generate the admin client certificate and private key:

```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin
```

Results:

```
admin-key.pem
admin.pem
```

### Create the kube-proxy client certificate

Create the kube-proxy client certificate signing request:

```
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "Cluster",
      "ST": "Oregon"
    }
  ]
}
EOF
```

Generate the kube-proxy client certificate and private key:

```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy
```

Results:

```
kube-proxy-key.pem
kube-proxy.pem
```

### Create the kubernetes server certificate

Set the Kubernetes Public IP Address

The Kubernetes public IP address will be included in the list of subject alternative names for the Kubernetes server certificate. This will ensure the TLS certificate is valid for remote client access.

#### GCE

```
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region us-central1 \
  --format 'value(address)')
```

#### AWS

```
KUBERNETES_PUBLIC_ADDRESS=$(aws elb describe-load-balancers \
  --load-balancer-name kubernetes | \
  jq -r '.LoadBalancerDescriptions[].DNSName')
```

---

Create the kubernetes server certificate signing request:

```
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "10.32.0.1",
    "10.240.0.10",
    "10.240.0.11",
    "10.240.0.12",
    "ip-10-240-0-10",
    "ip-10-240-0-11",
    "ip-10-240-0-12",
    "${KUBERNETES_PUBLIC_ADDRESS}",
    "127.0.0.1",
    "kubernetes.default"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Cluster",
      "ST": "Oregon"
    }
  ]
}
EOF
```

Generate the Kubernetes certificate and private key:

```
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes
```

Results:

```
kubernetes-key.pem
kubernetes.pem
```

## Distribute the TLS certificates

Set the list of Kubernetes hosts where the certs should be copied to:

```
KUBERNETES_WORKERS=(worker0 worker1 worker2)
```

```
KUBERNETES_CONTROLLERS=(controller0 controller1 controller2)
```

### GCE

The following command will:

* Copy the TLS certificates and keys to each Kubernetes host using the `gcloud compute copy-files` command.

```
for host in ${KUBERNETES_WORKERS[*]}; do
  gcloud compute copy-files ca.pem kube-proxy.pem kube-proxy-key.pem ${host}:~/
done
```

```
for host in ${KUBERNETES_CONTROLLERS[*]}; do
  gcloud compute copy-files ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem ${host}:~/
done
```

### AWS

The following command will:
 * Extract the public IP address for each Kubernetes host
 * Copy the TLS certificates and keys to each Kubernetes host using `scp`

```
for host in ${KUBERNETES_WORKERS[*]}; do
  PUBLIC_IP_ADDRESS=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${host}" | \
    jq -r '.Reservations[].Instances[].PublicIpAddress')
  scp -o "StrictHostKeyChecking no" ca.pem kube-proxy.pem kube-proxy-key.pem \
    ubuntu@${PUBLIC_IP_ADDRESS}:~/
done
```

```
for host in ${KUBERNETES_CONTROLLERS[*]}; do
  PUBLIC_IP_ADDRESS=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${host}" | \
    jq -r '.Reservations[].Instances[].PublicIpAddress')
  scp -o "StrictHostKeyChecking no" ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    ubuntu@${PUBLIC_IP_ADDRESS}:~/
done
```
