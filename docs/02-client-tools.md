# Installing the Client Tools

In this lab you will install the command line utilities required to complete this tutorial: [cfssl, cfssljson](https://github.com/cloudflare/cfssl), and [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl).

## Install CFSSL

The `cfssl` and `cfssljson` command line utilities will be used to provision a [public key infrastructure (PKI)](https://en.wikipedia.org/wiki/Public_key_infrastructure) and generate TLS certificates.

Download and install `cfssl` and `cfssljson`:

### OS X

```
ARCH='arm64'  # replace arm64 with amd64 if needed

curl --location --output cfssl --time-cond cfssl \
  "https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssl_1.6.4_darwin_${ARCH}"

curl --location --output cfssljson --time-cond cfssljson \
  "https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssljson_1.6.4_linux_${ARCH}"

chmod +x cfssl cfssljson

sudo mv cfssl cfssljson /usr/local/bin/
```

Some OS X users may experience problems using the pre-built binaries in which case [Homebrew](https://github.com/Homebrew/brew) might be a better option:

```
brew install cfssl
```

### Linux

```
curl --location --output cfssl --time-cond cfssl \
  https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssl_1.6.4_linux_amd64

curl --location --output cfssljson --time-cond cfssljson \
  https://github.com/cloudflare/cfssl/releases/download/v1.6.4/cfssljson_1.6.4_linux_amd64

sudo install --mode 0755 cfssl cfssljson /usr/local/bin/
```

### Verification

Verify `cfssl` and `cfssljson` version 1.6.4 or higher is installed:

```
cfssl version
```

> output

```
Version: 1.6.4
Runtime: go1.18
```

```
cfssljson --version
```

> output

```
Version: 1.6.4
Runtime: go1.18
```

## Install kubectl

The `kubectl` command line utility is used to interact with the Kubernetes API Server. Download and install `kubectl` from the official release binaries:

### OS X

```
curl --location --remote-name --time-cond kubectl \
  "https://dl.k8s.io/release/v1.27.4/bin/darwin/${ARCH}/kubectl"

chmod +x kubectl

sudo mv kubectl /usr/local/bin/
```

### Linux

```
curl --location --remote-name --time-cond kubectl \
  https://dl.k8s.io/release/v1.27.4/bin/linux/amd64/kubectl

sudo install --mode 0755 kubectl /usr/local/bin/
```

### Verification

Verify `kubectl` version 1.27.4 or higher is installed:

```
kubectl version --client --short
```

> output

```
Client Version: v1.27.4
Kustomize Version: v5.0.1
```

Next: [Provisioning Compute Resources](./03-compute-resources.md)
