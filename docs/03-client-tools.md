# Installing the Client Tools

First identify a system from where you will perform administrative tasks, such as creating certificates, kubeconfig files and distributing them to the different VMs.

If you are on a Linux laptop, then your laptop could be this system. In my case I chose the `master-1` node to perform administrative tasks. Whichever system you chose make sure that system is able to access all the provisioned VMs through SSH to copy files over.

## Access all VMs

Here we create an SSH key pair for the `vagrant` user who we are logged in as. We will copy the public key of this pair to the other master and both workers to permit us to use password-less SSH (and SCP) go get from `master-1` to these other nodes in the context of the `vagrant` user which exists on all nodes.

Generate Key Pair on `master-1` node

[//]: # (host:master-1)

```bash
ssh-keygen
```

Leave all settings to default by pressing `ENTER` at any prompt.

Add this key to the local authorized_keys (`master-1`) as in some commands we scp to ourself.

```bash
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

Copy the key to the other hosts. For this step please enter `vagrant` where a password is requested.

The option `-o StrictHostKeyChecking=no` tells it not to ask if you want to connect to a previously unknown host. Not best practice in the real world, but speeds things up here.

```bash
ssh-copy-id -o StrictHostKeyChecking=no vagrant@master-2
ssh-copy-id -o StrictHostKeyChecking=no vagrant@loadbalancer
ssh-copy-id -o StrictHostKeyChecking=no vagrant@worker-1
ssh-copy-id -o StrictHostKeyChecking=no vagrant@worker-2
```

For each host, the output should be similar to this. If it is not, then you may have entered an incorrect password. Retry the step.

```
Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'vagrant@master-2'"
and check to make sure that only the key(s) you wanted were added.
```

## Install kubectl

The [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl). command line utility is used to interact with the Kubernetes API Server. Download and install `kubectl` from the official release binaries:

Reference: [https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

We will be using kubectl early on to generate kubeconfig files for the controlplane components.

### Linux

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Verification

Verify `kubectl` is installed:

```
kubectl version -o yaml
```

> output will be similar to this, although versions may be newer

```
kubectl version -o yaml
clientVersion:
  buildDate: "2023-11-15T16:58:22Z"
  compiler: gc
  gitCommit: bae2c62678db2b5053817bc97181fcc2e8388103
  gitTreeState: clean
  gitVersion: v1.28.4
  goVersion: go1.20.11
  major: "1"
  minor: "28"
  platform: linux/amd64
kustomizeVersion: v5.0.4-0.20230601165947-6ce0bf390ce3

The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

Don't worry about the error at the end as it is expected. We have not set anything up yet!

Prev: [Compute Resources](02-compute-resources.md)<br>
Next: [Certificate Authority](04-certificate-authority.md)
