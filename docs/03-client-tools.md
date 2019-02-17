# Installing the Client Tools

In this chapter, you will install the command line utilities to `client-1`, required to complete this tutorial: [cfssl](https://github.com/cloudflare/cfssl), [cfssljson](https://github.com/cloudflare/cfssl), and [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl).

**All procedures in this chapter should be done in `client-1`.**


## Install CFSSL

The `cfssl` and `cfssljson` command line utilities will be used to provision a [PKI Infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure) and generate TLS certificates.

Download and install `cfssl` and `cfssljson` from the [cfssl repository](https://pkg.cfssl.org):

```
$ wget -q --show-progress --https-only --timestamping \
  https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
  https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
```

```
$ chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
```

```
$ sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
```

```
$ sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
```

### Verification

Verify `cfssl` version 1.2.0 or higher is installed:

```
$ cfssl version
```

> output

```
Version: 1.2.0
Revision: dev
Runtime: go1.6
```

> The cfssljson command line utility does not provide a way to print its version.

## Install kubectl

The `kubectl` command line utility is used to interact with the Kubernetes API Server. Download and install `kubectl` from the official release binaries:

```
$ wget https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl
```

```
$ chmod +x kubectl
```

```
$ sudo mv kubectl /usr/local/bin/
```

### Verification

Verify `kubectl` version 1.12.0 or higher is installed:

```
$ kubectl version --client
```

> output

```
Client Version: version.Info{Major:"1", Minor:"12", GitVersion:"v1.12.0", GitCommit:"0ed33881dc4355495f623c6f22e7dd0b7632b7c0", GitTreeState:"clean", BuildDate:"2018-09-27T17:05:32Z", GoVersion:"go1.10.4", Compiler:"gc", Platform:"linux/amd64"}
```


Next: [Provisioning a CA and Generating TLS Certificates](04-certificate-authority.md)
