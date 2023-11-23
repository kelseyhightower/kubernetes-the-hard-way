# Installing Container Runtime on the Kubernetes Worker Nodes

In this lab you will install the Container Runtime Interface (CRI) on both worker nodes. CRI is a standard interface for the management of containers. Since v1.24 the use of dockershim has been fully deprecated and removed from the code base. [containerd replaces docker](https://kodekloud.com/blog/kubernetes-removed-docker-what-happens-now/) as the container runtime for Kubernetes, and it requires support from [CNI Plugins](https://github.com/containernetworking/plugins) to configure container networks, and [runc](https://github.com/opencontainers/runc) to actually do the job of running containers.

Reference: https://github.com/containerd/containerd/blob/main/docs/getting-started.md

### Download and Install Container Networking

The commands in this lab must be run on each worker instance: `worker-1`, and `worker-2`. Login to each controller instance using SSH Terminal.

Here we will install the container runtime `containerd` from the Ubuntu distribution, and kubectl plus the CNI tools from the Kubernetes distribution. Kubectl is required on worker-2 to initialize kubeconfig files for the worker-node auto registration.

[//]: # (host:worker-1-worker-2)

You can perform this step with [tmux](01-prerequisites.md#running-commands-in-parallel-with-tmux)

Set up the Kubernetes `apt` repository

```bash
{
  KUBE_LATEST=$(curl -L -s https://dl.k8s.io/release/stable.txt | awk 'BEGIN { FS="." } { printf "%s.%s", $1, $2 }')

  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBE_LATEST}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBE_LATEST}/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
}
```

Install `containerd` and CNI tools, first refreshing `apt` repos to get up to date versions.

```bash
{
  sudo apt update
  sudo apt install -y containerd kubernetes-cni kubectl ipvsadm ipset
}
```

Set up `containerd` configuration to enable systemd Cgroups

```bash
{
  sudo mkdir -p /etc/containerd
  containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/' | sudo tee /etc/containerd/config.toml
}
```

Now restart `containerd` to read the new configuration

```bash
sudo systemctl restart containerd
```


Prev: [Bootstrapping the Kubernetes Control Plane](08-bootstrapping-kubernetes-controllers.md)</br>
Next: [Bootstrapping the Kubernetes Worker Nodes](10-bootstrapping-kubernetes-workers.md)
