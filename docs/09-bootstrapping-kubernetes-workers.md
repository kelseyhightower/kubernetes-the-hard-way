# Bootstrapping the Kubernetes Worker Nodes

In this lab you will bootstrap three Kubernetes worker nodes. The following components will be installed on each node: [containerd](https://github.com/containerd/containerd), [runc](https://github.com/opencontainers/runc), [container networking plugins](https://github.com/containernetworking/plugins), [crictl](https://github.com/kubernetes-sigs/cri-tools), [kube-proxy](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/), [kubectl](https://kubernetes.io/docs/reference/kubectl/), and [kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/).

## Prerequisites

The commands in this lab must be run on each worker instance: `worker-0`, `worker-1`, and `worker-2`. Login to each worker instance using the `gcloud` command. Example:

```
gcloud compute ssh worker-0
```

### Running commands in parallel with tmux

[tmux](https://tmux.github.io/) can be used to run commands on multiple compute instances at the same time. See the [Running commands in parallel with tmux](./01-prerequisites.md#running-commands-in-parallel-with-tmux) section in the Prerequisites lab.

## Provisioning a Kubernetes Worker Node

Install the OS dependencies ([conntrack](https://conntrack-tools.netfilter.org/), [ipset](https://ipset.netfilter.org/), and [socat](socat)):

```
sudo apt-get update

sudo apt-get --yes install conntrack ipset socat
```

> The socat binary enables support for the `kubectl port-forward` command.

### Disable Swap

By default the kubelet will fail to start if [swap](https://help.ubuntu.com/community/SwapFaq) is enabled. It is [recommended](https://github.com/kubernetes/kubernetes/issues/7294) that swap be disabled to ensure Kubernetes can provide proper resource allocation and quality of service.

Verify if swap is enabled:

```
sudo swapon --show
```

If output is empty then swap is not enabled. If swap is enabled run the following command to disable swap immediately:

```
sudo swapoff --all
```

> To ensure swap remains off after reboot consult your Linux distro documentation.

### Download and Install Worker Binaries

```
curl --location \
  --remote-name --time-cond containerd-1.7.3-linux-amd64.tar.gz \
  https://github.com/containerd/containerd/releases/download/v1.7.3/containerd-1.7.3-linux-amd64.tar.gz \
  --remote-name --time-cond containerd.service \
  https://raw.githubusercontent.com/containerd/containerd/v1.7.3/containerd.service \
  --output runc --time-cond runc \
  https://github.com/opencontainers/runc/releases/download/v1.1.8/runc.amd64 \
  --remote-name --time-cond cni-plugins-linux-amd64-v1.3.0.tgz \
  https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz \
  --remote-name --time-cond crictl-v1.27.1-linux-amd64.tar.gz \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.27.1/crictl-v1.27.1-linux-amd64.tar.gz \
  --remote-name --time-cond kube-proxy \
  https://dl.k8s.io/release/v1.27.4/bin/linux/amd64/kube-proxy \
  --remote-name --time-cond kubectl \
  https://dl.k8s.io/release/v1.27.4/bin/linux/amd64/kubectl \
  --remote-name --time-cond kubelet \
  https://dl.k8s.io/release/v1.27.4/bin/linux/amd64/kubelet
```

Create the installation directories:

```
sudo mkdir --parents \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kube-proxy \
  /var/lib/kubelet \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

Install the worker binaries:

```
sudo tar --directory /usr/local/ --extract \
  --file containerd-1.7.3-linux-amd64.tar.gz --gunzip --verbose

sudo mkdir --parents /usr/local/lib/systemd/system

sudo cp containerd.service /usr/local/lib/systemd/system/

sudo install --mode 0755 runc /usr/local/sbin/

tar --extract --file crictl-v1.27.1-linux-amd64.tar.gz --gunzip --verbose

sudo tar --directory /opt/cni/bin/ --extract \
  --file cni-plugins-linux-amd64-v1.3.0.tgz --gunzip --verbose

sudo install --mode 0755 crictl kube-proxy kubectl kubelet /usr/local/bin/
```

### Configure CNI Networking

Retrieve the Pod CIDR range for the current compute instance:

```
POD_CIDR="$(curl --silent --header 'Metadata-Flavor: Google' \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/pod-cidr)"
```

Create the CNI config file:

```
cat << EOF | sudo tee /etc/cni/net.d/10-containerd-net.conflist
{
 "cniVersion": "1.0.0",
 "name": "containerd-net",
 "plugins": [
   {
     "type": "bridge",
     "bridge": "cni0",
     "isGateway": true,
     "ipMasq": true,
     "promiscMode": true,
     "ipam": {
       "type": "host-local",
       "ranges": [
         [{
           "subnet": "${POD_CIDR}"
         }]
       ],
       "routes": [
         { "dst": "0.0.0.0/0" }
       ]
     }
   },
   {
     "type": "portmap",
     "capabilities": {"portMappings": true},
     "externalSetMarkChain": "KUBE-MARK-MASQ"
   }
 ]
}
EOF
```

### Configure containerd

Create the `containerd` configuration file:

```
sudo mkdir --parents /etc/containerd

containerd config default | sudo tee /etc/containerd/config.toml
```

### Configure the Kubelet

```
sudo cp "${HOSTNAME}-key.pem" "${HOSTNAME}.pem" /var/lib/kubelet/

sudo cp "${HOSTNAME}.kubeconfig" /var/lib/kubelet/kubeconfig

sudo cp ca.pem /var/lib/kubernetes/
```

Create the `kubelet-config.yaml` configuration file:

```
cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
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
cat <<EOF | sudo tee /usr/local/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config /var/lib/kubelet/kubelet-config.yaml \\
  --container-runtime-endpoint unix:///var/run/containerd/containerd.sock \\
  --kubeconfig /var/lib/kubelet/kubeconfig \\
  --register-node \\
  --v 2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubernetes Proxy

```
sudo cp kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
```

Create the `kube-proxy-config.yaml` configuration file:

```
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
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
cat <<EOF | sudo tee /usr/local/lib/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config /var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Start the Worker Services

```
sudo systemctl enable --now containerd kubelet kube-proxy
```

> Remember to run the above commands on each worker node: `worker-0`, `worker-1`, and `worker-2`.

## Verification

> The compute instances created in this tutorial will not have permission to complete this section. Run the following commands from the same machine used to create the compute instances.

List the registered Kubernetes nodes:

```
gcloud compute ssh controller-0 \
  --command 'kubectl get nodes --kubeconfig admin.kubeconfig'
```

> output

```
NAME       STATUS   ROLES    AGE   VERSION
worker-0   Ready    <none>   37s   v1.27.4
worker-1   Ready    <none>   37s   v1.27.4
worker-2   Ready    <none>   37s   v1.27.4
```

Next: [Configuring kubectl for Remote Access](./10-configuring-kubectl.md)
