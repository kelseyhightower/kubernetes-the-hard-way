# Setting up a Certificate Authority and TLS Cert Generation

In this lab you will setup the necessary PKI infrastructure to secure the Kuberentes components. This lab will leverage CloudFlare's PKI toolkit, [cfssl](https://github.com/cloudflare/cfssl), to bootstrap a Certificate Authority and generate TLS certificates.

This lab will setup a Certificate Authority and generated a single set of TLS certificates that can be used to secure the following Kubernetes components:

* etcd
* Kubernetes API Server
* Kubernetes Kubelet

> In production you should strongly consider generating individual TLS certificates for each component.

The TLS certificates in this lab will be copied to each machine running a Kubernetes components. 

## Install CFSSL

Follow the [CFSSL installation guide](https://github.com/cloudflare/cfssl#installation) and install `cfssl` and `cfssljson` binaries.

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

```
echo '{
  "CN": "kubernetes",
  "hosts": [
    "10.240.0.10",
    "10.240.0.11",
    "10.240.0.12",
    "10.240.0.20",
    "10.240.0.21",
    "10.240.0.22",
    "10.240.0.30",
    "10.240.0.31",
    "10.240.0.32",
    "146.148.34.151",
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
}' > kubernetes-csr.json
```

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