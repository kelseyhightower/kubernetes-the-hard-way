# Set Up The Jumpbox

In this lab you will set up one of the four machines to be a `jumpbox`. This machine will be used to run commands in this tutorial. While a dedicated machine is being used to ensure consistency, these commands can also be run from just about any machine including your personal workstation running macOS or Linux.

Think of the `jumpbox` as the administration machine that you will use as a home base when setting up your Kubernetes cluster from the ground up. One thing we need to do before we get started is install a few command line utilities and clone the Kubernetes The Hard Way git repository, which contains some additional configuration files that will be used to configure various Kubernetes components throughout this tutorial. 

Log in to the `jumpbox`:

```bash
ssh root@jumpbox
```

All commands will be run as the `root` user. This is being done for the sake of convenience, and will help reduce the number of commands required to set everything up.

### Install Command Line Utilities

Now that you are logged into the `jumpbox` machine as the `root` user, you will install the command line utilities that will be used to preform various tasks throughout the tutorial. 

```bash
apt-get -y install wget curl vim openssl git
```

### Sync GitHub Repository

Now it's time to download a copy of this tutorial which contains the configuration files and templates that will be used build your Kubernetes cluster from the ground up. Clone the Kubernetes The Hard Way git repository using the `git` command:

```bash
git clone --depth 1 \
  https://github.com/kelseyhightower/kubernetes-the-hard-way.git
```

Change into the `kubernetes-the-hard-way` directory:

```bash
cd kubernetes-the-hard-way
```

This will be the working directory for the rest of the tutorial. If you ever get lost run the `pwd` command to verify you are in the right directory when running commands on the `jumpbox`:

```bash
pwd
```

```text
/root/kubernetes-the-hard-way
```

### Download Binaries

In this section you will download the binaries for the various Kubernetes components. The binaries will be stored in the `downloads` directory on the `jumpbox`, which will reduce the amount of internet bandwidth required to complete this tutorial as we avoid downloading the binaries multiple times for each machine in our Kubernetes cluster.

The binaries that will be downloaded are listed in the `downloads.txt` file, which you can review using the `cat` command:

```bash
cat downloads.txt
```

Download the binaries listed in the `downloads.txt` file into a directory called `downloads` using the `wget` command:

```bash
wget -q --show-progress \
  --https-only \
  --timestamping \
  -P downloads \
  -i downloads.txt
```

Depending on your internet connection speed it may take a while to download the `584` megabytes of binaries, and once the download is complete, you can list them using the `ls` command:

```bash
ls -loh downloads
```

```text
total 510M
-rw-r--r-- 1 root 48M Oct 15 02:37 cni-plugins-linux-arm64-v1.6.0.tgz
-rw-r--r-- 1 root 32M Nov  5 11:37 containerd-2.0.0-linux-arm64.tar.gz
-rw-r--r-- 1 root 17M Aug 13 03:48 crictl-v1.31.1-linux-arm64.tar.gz
-rw-r--r-- 1 root 16M Sep 11 11:28 etcd-v3.4.34-linux-arm64.tar.gz
-rw-r--r-- 1 root 84M Oct 22 21:41 kube-apiserver
-rw-r--r-- 1 root 79M Oct 22 21:41 kube-controller-manager
-rw-r--r-- 1 root 53M Oct 22 21:41 kubectl
-rw-r--r-- 1 root 72M Oct 22 21:41 kubelet
-rw-r--r-- 1 root 61M Oct 22 21:41 kube-proxy
-rw-r--r-- 1 root 60M Oct 22 21:41 kube-scheduler
-rw-r--r-- 1 root 11M Nov  1 15:23 runc.arm64
```

### Install kubectl

In this section you will install the `kubectl`, the official Kubernetes client command line tool, on the `jumpbox` machine. `kubectl will be used to interact with the Kubernetes control once your cluster is provisioned later in this tutorial.

Use the `chmod` command to make the `kubectl` binary executable and move it to the `/usr/local/bin/` directory:

```bash
{
  chmod +x downloads/kubectl
  cp downloads/kubectl /usr/local/bin/
}
```

At this point `kubectl` is installed and can be verified by running the `kubectl` command:

```bash
kubectl version --client
```

```text
Client Version: v1.31.2
Kustomize Version: v5.4.2
```

At this point the `jumpbox` has been set up with all the command line tools and utilities necessary to complete the labs in this tutorial.

Next: [Provisioning Compute Resources](03-compute-resources.md)
