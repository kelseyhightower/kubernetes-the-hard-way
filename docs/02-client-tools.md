# Installing the Client Tools

In this lab you will install the command line utilities required to complete this tutorial: [cfssl](https://github.com/cloudflare/cfssl), [cfssljson](https://github.com/cloudflare/cfssl), and [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl).


## Install CFSSL

The `cfssl` and `cfssljson` command line utilities will be used to provision a [PKI Infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure) and generate TLS certificates.

Download and install `cfssl` and `cfssljson` from the [cfssl repository](https://pkg.cfssl.org):

### OS X

```sh
curl -o cfssl https://pkg.cfssl.org/R1.2/cfssl_darwin-amd64
curl -o cfssljson https://pkg.cfssl.org/R1.2/cfssljson_darwin-amd64
```

```sh
chmod +x cfssl cfssljson
```

```sh
sudo mv cfssl cfssljson /usr/local/bin/
```

Some OS X users may experience problems using the pre-built binaries in which case [Homebrew](https://brew.sh) might be a better option:

```sh
brew install cfssl
```

### Linux

```sh
wget -q --show-progress --https-only --timestamping \
  https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
  https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
```

```sh
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
```

```sh
sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
```

```sh
sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
```

### Verification

Verify `cfssl` version 1.2.0 or higher is installed:

```sh
cfssl version
```

> output

```
Version: 1.3.4
Revision: dev
Runtime: go1.12.7
```

> The cfssljson command line utility does not provide a way to print its version.

## Install kubectl

The `kubectl` command line utility is used to interact with the Kubernetes API Server.
Download and install latest stable `kubectl` from the official release binaries:

### OS X

```sh
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl"
```

```sh
chmod +x kubectl
```

```sh
sudo mv kubectl /usr/local/bin/
```

### Linux

```sh
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
```

```sh
chmod +x kubectl
```

```sh
sudo mv kubectl /usr/local/bin/
```

### Verification

Verify `kubectl` version 1.14.0 or higher is installed:

```sh
kubectl version --client
```

> output

```
Client Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.1", GitCommit:"4485c6f18cee9a5d3c3b4e523bd27972b1b53892", GitTreeState:"clean", BuildDate:"2019-07-18T09:18:22Z", GoVersion:"go1.12.5", Compiler:"gc", Platform:"darwin/amd64"}
```

Next: [Provisioning Compute Resources](03-compute-resources.md)
