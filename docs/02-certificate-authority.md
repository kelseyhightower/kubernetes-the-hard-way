# Setting up a Certificate Authority and TLS Cert Generation

In this lab you will setup the necessary PKI infrastructure to secure the Kubernetes components. This lab will leverage CloudFlare's PKI toolkit, [cfssl](https://github.com/cloudflare/cfssl), to bootstrap a Certificate Authority and generate TLS certificates.

In this lab you will generate a single set of TLS certificates that can be used to secure the following Kubernetes components:

* etcd
* Kubernetes API Server
* Kubernetes Kubelet

> In production you should strongly consider generating individual TLS certificates for each component.

After completing this lab you should have the following TLS keys and certificates:

```
ca-key.pem
ca.pem
kubernetes-key.pem
kubernetes.pem
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

## Setting up a Certificate Authority

### Create the CA configuration file

```
echo '{
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
}' > ca-config.json
```

### Generate the CA certificate and private key

Create the CA CSR:

```
echo '{
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
}' > ca-csr.json
```

Generate the CA certificate and private key:

```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

Results:

```
ca-key.pem
ca.csr
ca.pem
```

### Verification

```
openssl x509 -in ca.pem -text -noout
```

## Generate the single Kubernetes TLS Cert

In this section we will generate a TLS certificate that will be valid for all Kubernetes components. This is being done for ease of use. In production you should strongly consider generating individual TLS certificates for each component.

Create the `kubernetes-csr.json` file:

```
export KUBERNETES_PUBLIC_IP_ADDRESS=$(gcloud compute addresses describe kubernetes \
  --format 'value(address)')
```

```
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "worker0",
    "worker1",
    "worker2",
    "10.32.0.1",
    "10.240.0.10",
    "10.240.0.11",
    "10.240.0.12",
    "10.240.0.20",
    "10.240.0.21",
    "10.240.0.22",
    "10.240.0.30",
    "10.240.0.31",
    "10.240.0.32",
    "${KUBERNETES_PUBLIC_IP_ADDRESS}",
    "127.0.0.1"
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
kubernetes.csr
kubernetes.pem
```

### Verification

```
openssl x509 -in kubernetes.pem -text -noout
```

## Copy TLS Certs

```
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem controller0:~/
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem controller1:~/
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem controller2:~/
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem etcd0:~/
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem etcd1:~/
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem etcd2:~/
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem worker0:~/
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem worker1:~/
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem worker2:~/
```
