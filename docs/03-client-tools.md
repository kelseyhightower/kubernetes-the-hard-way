# Installing the Client Tools

First identify a system from where you will perform administrative tasks, such as creating certificates, kubeconfig files and distributing them to the different VMs.

If you are on a Linux laptop, then your laptop could be this system. In my case I chose the `master-1` node to perform administrative tasks. Whichever system you chose make sure that system is able to access all the provisioned VMs through SSH to copy files over.

## Access all VMs

Here we create an SSH key pair for the `vagrant` user who we are logged in as. We will copy the public key of this pair to the other master and both workers to permit us to use password-less SSH (and SCP) go get from `master-1` to these other nodes in the context of the `vagrant` user which exists on all nodes.

Generate Key Pair on `master-1` node

```bash
ssh-keygen
```

Leave all settings to default.

View the generated public key ID at:

```bash
cat ~/.ssh/id_rsa.pub
```

Add this key to the local authorized_keys (`master-1`) as in some commands we scp to ourself

```bash
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

Copy the output into a notepad and form it into the following command

```bash
cat >> ~/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD...OUTPUT-FROM-ABOVE-COMMAND...8+08b vagrant@master-1
EOF
```

Now ssh to each of the other nodes and paste the above from your notepad at each command prompt.

## Install kubectl

The [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl). command line utility is used to interact with the Kubernetes API Server. Download and install `kubectl` from the official release binaries:

Reference: [https://kubernetes.io/docs/tasks/tools/install-kubectl/](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

### Linux

```bash
wget https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### Verification

Verify `kubectl` version 1.24.3 or higher is installed:

```
kubectl version -o yaml
```

> output

```
kubectl version -o yaml
clientVersion:
  buildDate: "2022-07-13T14:30:46Z"
  compiler: gc
  gitCommit: aef86a93758dc3cb2c658dd9657ab4ad4afc21cb
  gitTreeState: clean
  gitVersion: v1.24.3
  goVersion: go1.18.3
  major: "1"
  minor: "24"
  platform: linux/amd64
kustomizeVersion: v4.5.4

The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

Don't worry about the error at the end as it is expected. We have not set anything up yet!

Prev: [Compute Resources](02-compute-resources.md)<br>
Next: [Certificate Authority](04-certificate-authority.md)
