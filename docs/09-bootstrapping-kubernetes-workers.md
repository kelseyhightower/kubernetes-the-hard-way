# Bootstrapping the Kubernetes Worker Nodes

In this lab you will bootstrap three Kubernetes worker nodes. The following components will be installed on each node: [runc](https://github.com/opencontainers/runc), [container networking plugins](https://github.com/containernetworking/cni), [containerd](https://github.com/containerd/containerd), [kubelet](https://kubernetes.io/docs/admin/kubelet), and [kube-proxy](https://kubernetes.io/docs/concepts/cluster-administration/proxies).

## Prerequisites

The commands in this lab must be run on each worker instance: `worker-0`, `worker-1`, and `worker-2`. Login to each worker instance using the `gcloud` command. Example:

```
$ aws ec2 describe-instances --filters Name=vpc-id,Values=vpc-xxxxxxxxxxxxxxxxx \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value | [0],InstanceId,Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress,State.Name]' \
  --output text | sort | grep worker
worker-0        i-aaaaaaaaaaaaaaaaa     ap-northeast-1c 10.240.0.20    x.xxx.xx.xx     running
...

$ ssh -i ~/.ssh/your_ssh_key ubuntu@x.xxx.xx.xx
```

### Running commands in parallel with tmux

[tmux](https://github.com/tmux/tmux/wiki) can be used to run commands on multiple EC2 instances at the same time. See the [Running commands in parallel with tmux](01-prerequisites.md#running-commands-in-parallel-with-tmux) section in the Prerequisites lab.

## Provisioning a Kubernetes Worker Node

Install the OS dependencies:

```
worker-x $ sudo apt-get update
worker-x $ sudo apt-get -y install socat conntrack ipset
```

> The socat binary enables support for the `kubectl port-forward` command.

### Disable Swap

By default the kubelet will fail to start if [swap](https://help.ubuntu.com/community/SwapFaq) is enabled. It is [recommended](https://github.com/kubernetes/kubernetes/issues/7294) that swap be disabled to ensure Kubernetes can provide proper resource allocation and quality of service.

Verify if swap is enabled:

```
worker-x $ sudo swapon --show
```

If output is empthy then swap is not enabled. If swap is enabled run the following command to disable swap immediately:

```
worker-x $ sudo swapoff -a
```

> To ensure swap remains off after reboot consult your Linux distro documentation.

### Download and Install Worker Binaries

```
worker-x $ wget -q --show-progress --https-only --timestamping \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.15.0/crictl-v1.15.0-linux-amd64.tar.gz \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.amd64 \
  https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz \
  https://github.com/containerd/containerd/releases/download/v1.2.9/containerd-1.2.9.linux-amd64.tar.gz \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubelet
```

Create the installation directories:

```
worker-x $ sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

Install the worker binaries:

```
worker-x $ mkdir containerd
worker-x $ tar -xvf crictl-v1.15.0-linux-amd64.tar.gz
worker-x $ tar -xvf containerd-1.2.9.linux-amd64.tar.gz -C containerd
worker-x $ sudo tar -xvf cni-plugins-linux-amd64-v0.8.2.tgz -C /opt/cni/bin/
worker-x $ sudo mv runc.amd64 runc
worker-x $ chmod +x crictl kubectl kube-proxy kubelet runc 
worker-x $ sudo mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
worker-x $ sudo mv containerd/bin/* /bin/
```

Verify:

```
worker-x $ ls /opt/cni/bin/
bandwidth  bridge  dhcp  firewall  flannel  host-device  host-local  ipvlan  loopback  macvlan  portmap  ptp  sbr  static  tuning  vlan

worker-x $ ls /bin/container*
/bin/containerd  /bin/containerd-shim  /bin/containerd-shim-runc-v1  /bin/containerd-stress
worker-x $ ls /usr/local/bin/
crictl  kube-proxy  kubectl  kubelet  runc
```

### Configure CNI Networking

Retrieve the Pod CIDR range for the current EC2 instance. Remember that we've put Pod CIDR range by executing `echo 10.200.x.0/24 > /opt/pod_cidr.txt` in [cloudformation/worker-nodes.cfn.yml](../cloudformation/hard-k8s-worker-nodes.cfn.yml) via UserData.

Example:

```
worker-0 $ cat /opt/pod_cidr.txt
10.200.0.0/24
```

Save these ranges in the environment variable named `POD_CIDR`.

```
worker-x $ POD_CIDR=$(cat /opt/pod_cidr.txt)
```

Create the `bridge` network configuration file:

```
worker-x $ cat <<EOF | sudo tee /etc/cni/net.d/10-bridge.conf
{
    "cniVersion": "0.3.1",
    "name": "bridge",
    "type": "bridge",
    "bridge": "cnio0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "ranges": [
          [{"subnet": "${POD_CIDR}"}]
        ],
        "routes": [{"dst": "0.0.0.0/0"}]
    }
}
EOF
```

Create the `loopback` network configuration file:

```
worker-x $ cat <<EOF | sudo tee /etc/cni/net.d/99-loopback.conf
{
    "cniVersion": "0.3.1",
    "name": "lo",
    "type": "loopback"
}
EOF
```

### Configure containerd

Create the `containerd` configuration file:

```
worker-x $ sudo mkdir -p /etc/containerd/
```

```
worker-x $ cat << EOF | sudo tee /etc/containerd/config.toml
[plugins]
  [plugins.cri.containerd]
    snapshotter = "overlayfs"
    [plugins.cri.containerd.default_runtime]
      runtime_type = "io.containerd.runtime.v1.linux"
      runtime_engine = "/usr/local/bin/runc"
      runtime_root = ""
EOF
```

Create the `containerd.service` systemd unit file:

```
worker-x $ cat <<EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubelet

Check an environment variable `$HOSTNAME`.

```
worker-0 $ echo $HOSTNAME
worker-0
```

```
worker-x $ sudo mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem /var/lib/kubelet/
worker-x $ sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
worker-x $ sudo mv ca.pem /var/lib/kubernetes/
```

Create the `kubelet-config.yaml` configuration file:

```
worker-x $ cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.32.0.10"
podCIDR: "${POD_CIDR}"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
tlsCertFile: "/var/lib/kubelet/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/var/lib/kubelet/${HOSTNAME}-key.pem"
EOF
```

> The `resolvConf` configuration is used to avoid loops when using CoreDNS for service discovery on systems running `systemd-resolved`. 

Create the `kubelet.service` systemd unit file:

```
worker-x $ cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

See details of kubelet options in [the document](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/). Note that `--cni-conf-dir` default is `/etc/cni/net.d`, and `--cni-bin-dir` default is `/opt/cni/bin`.


### Configure the Kubernetes Proxy

```
worker-x $ sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
```

Create the `kube-proxy-config.yaml` configuration file:

```
worker-x $ cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF
```

Create the `kube-proxy.service` systemd unit file:

```
worker-x $ cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Start the Worker Services

```
worker-x $ sudo systemctl daemon-reload
worker-x $ sudo systemctl enable containerd kubelet kube-proxy
worker-x $ sudo systemctl start containerd kubelet kube-proxy
```

> Remember to run the above commands on each worker node: `worker-0`, `worker-1`, and `worker-2`.

## Verification

> The EC2 instances created in this tutorial will not have permission to complete this section. Run the following commands from the same machine used to create the EC2 instances.

List the registered Kubernetes nodes:

```
$ aws ec2 describe-instances --filters Name=vpc-id,Values=vpc-xxxxxxxxxxxxxxxxx \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value | [0],InstanceId,Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress,State.Name]' \
  --output text | sort | grep master-0
master-0        i-xxxxxxxxxxxxxxxxx     ap-northeast-1d 10.240.0.10     xx.xxx.xx.xx    running

$ ssh -i ~/.ssh/your_ssh_key ubuntu@xx.xxx.xx.xx "kubectl get nodes --kubeconfig admin.kubeconfig"
NAME       STATUS   ROLES    AGE     VERSION
worker-0   Ready    <none>   2m18s   v1.15.3
worker-1   Ready    <none>   2m18s   v1.15.3
worker-2   Ready    <none>   2m18s   v1.15.3
```

Now 3 workers have been registered to the cluster.

Next: [Configuring kubectl for Remote Access](10-configuring-kubectl.md)