# Installing CRI on the Kubernetes Worker Nodes

In this lab you will install the Container Runtime Interface (CRI) on both worker nodes. CRI is a standard interface for the management of containers. Since v1.24 the use of dockershim has been fully deprecated and removed from the code base. [containerd replaces docker](https://kodekloud.com/blog/kubernetes-removed-docker-what-happens-now/) as the container runtime for Kubernetes, and it requires support from [CNI Plugins](https://github.com/containernetworking/plugins) to configure container networks, and [runc](https://github.com/opencontainers/runc) to actually do the job of running containers.

Reference: https://github.com/containerd/containerd/blob/main/docs/getting-started.md

### Download and Install Container Networking

The commands in this lab must be run on each worker instance: `worker-1`, and `worker-2`. Login to each controller instance using SSH Terminal.

[//]: # (host:worker-1-worker-2)

You can perform this step with [tmux](01-prerequisites.md#running-commands-in-parallel-with-tmux)

The versions chosen here align with those that are installed by the current `kubernetes-cni` package for a v1.24 cluster.

```bash
{
  CONTAINERD_VERSION=1.5.9
  CNI_VERSION=0.8.6
  RUNC_VERSION=1.1.1

  wget -q --show-progress --https-only --timestamping \
    https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz \
    https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz \
    https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.amd64

  sudo mkdir -p /opt/cni/bin

  sudo chmod +x runc.amd64
  sudo mv runc.amd64 /usr/local/bin/runc

  sudo tar -xzvf containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz -C /usr/local
  sudo tar -xzvf cni-plugins-linux-amd64-v${CNI_VERSION}.tgz -C /opt/cni/bin
}
```

Next create the `containerd` service unit.

```bash
cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
```

Now start it

```bash
{
  sudo systemctl enable containerd
  sudo systemctl start containerd
}
```

Prev: [Bootstrapping the Kubernetes Control Plane](08-bootstrapping-kubernetes-controllers.md)</br>
Next: [Bootstrapping the Kubernetes Worker Nodes](10-bootstrapping-kubernetes-workers.md)
