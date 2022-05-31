# Installing the Client Tools

In this lab you will install the command line utilities required to complete this tutorial: [step](https://github.com/smallstep/cli), and [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl).


## Install CFSSL

The `step` command line utility will be used to provision a [PKI Infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure) and generate TLS certificates.

Download and install `step`:

### OS X

For Intel chips:

```
curl -L https://dl.step.sm/gh-release/cli/gh-release-header/v0.20.0/step_darwin_0.20.0_amd64.tar.gz | tar xz
sudo mv step_0.20.0/bin/step /usr/local/bin/
```

For Apple Silicon:

```
curl -L https://dl.step.sm/gh-release/cli/gh-release-header/v0.20.0/step_darwin_0.20.0_arm64.tar.gz | tar xz
sudo mv step_0.20.0/bin/step /usr/local/bin/
```

Or, if you'd like to use [Homebrew](https://brew.sh):

```
brew install step
```

### Linux

```
curl -L https://dl.step.sm/gh-release/cli/gh-release-header/v0.20.0/step_linux_0.20.0_amd64.tar.gz | tar xz
sudo mv step_0.20.0/bin/step /usr/local/bin/
```

### Verification

Verify `step` version 0.20.0 or higher is installed:

```
step version
```

> output

```
Smallstep CLI/0.20.0 (darwin/arm64)
Release Date: 2022-05-26 19:31 UTC
```

## Install kubectl

The `kubectl` command line utility is used to interact with the Kubernetes API Server. Download and install `kubectl` from the official release binaries:

### OS X

```
curl -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/darwin/amd64/kubectl
```

```
chmod +x kubectl
```

```
sudo mv kubectl /usr/local/bin/
```

### Linux

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl
```

```
chmod +x kubectl
```

```
sudo mv kubectl /usr/local/bin/
```

### Verification

Verify `kubectl` version 1.21.0 or higher is installed:

```
kubectl version --client
```

> output

```
Client Version: version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.0", GitCommit:"cb303e613a121a29364f75cc67d3d580833a7479", GitTreeState:"clean", BuildDate:"2021-04-08T16:31:21Z", GoVersion:"go1.16.1", Compiler:"gc", Platform:"linux/amd64"}
```

Next: [Provisioning Compute Resources](03-compute-resources.md)
