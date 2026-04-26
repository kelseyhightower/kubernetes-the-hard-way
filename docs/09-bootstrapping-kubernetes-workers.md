# Bootstrapping the Kubernetes Worker Nodes

In this lab you will bootstrap two Kubernetes worker nodes. The following components will be installed: [runc](https://github.com/opencontainers/runc), [container networking plugins](https://github.com/containernetworking/cni), [containerd](https://github.com/containerd/containerd), [kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet), and [kube-proxy](https://kubernetes.io/docs/concepts/cluster-administration/proxies).

## What You Are Building

This lab turns `node-0` and `node-1` into Kubernetes worker nodes. A worker node needs a container runtime, Pod networking, a kubelet, and kube-proxy.

```text
jumpbox
  |
  | render per-node configs
  |   - 10-bridge.conf       uses each node's Pod CIDR
  |   - kubelet-config.yaml  uses each node's Pod CIDR
  |
  | copy worker binaries, CNI plugins, kubeconfigs, certs, and systemd units
  v
node-0 / node-1
```

Each worker is assembled like this:

```text
worker node
  |
  +-- containerd
  |     +-- runs Pods through the CRI socket
  |     +-- uses runc as the low-level OCI runtime
  |
  +-- CNI plugins
  |     +-- bridge
  |     +-- host-local
  |     +-- loopback
  |     +-- allocate Pod IPs from this node's Pod CIDR
  |
  +-- kubelet
  |     +-- reads /var/lib/kubelet/kubeconfig
  |     +-- authenticates as system:node:<node-name>
  |     +-- talks to https://server.kubernetes.local:6443
  |     +-- registers the Node with the API server
  |
  +-- kube-proxy
        +-- reads /var/lib/kube-proxy/kubeconfig
        +-- programs Service traffic rules
```

The most important dependency chain is:

```text
/etc/hosts resolves server.kubernetes.local
        |
        v
kubelet kubeconfig reaches https://server.kubernetes.local:6443
        |
        v
kubelet presents kubelet certificate identity
        |
        v
API server authenticates system:node:<node-name>
        |
        v
Node appears in kubectl get nodes
```

If `kubectl get nodes` returns no nodes, check the kubelet logs first. Errors such as `Could not resolve host: server.kubernetes.local` or `lookup server.kubernetes.local ... i/o timeout` mean the host lookup table from the compute resources lab was not applied to the worker nodes.

## Prerequisites

The commands in this section must be run from the `jumpbox`.

Verify the worker binaries and CNI plugins exist on the `jumpbox` before copying them to the worker nodes:

```bash
{
  test -f downloads/worker/crictl
  test -f downloads/worker/containerd
  test -f downloads/worker/containerd-shim-runc-v2
  test -f downloads/worker/containerd-stress
  test -f downloads/worker/kubelet
  test -f downloads/worker/kube-proxy
  test -f downloads/worker/runc
  test -f downloads/cni-plugins/bridge
  test -f downloads/cni-plugins/host-local
  test -f downloads/cni-plugins/loopback
}
```

If any of these checks fail, return to the [Setting up the Jumpbox](02-jumpbox.md) lab and re-run the download extraction and verification steps before continuing.

Copy the Kubernetes binaries and systemd unit files to each worker instance:

```bash
for HOST in node-0 node-1; do
  SUBNET=$(grep ${HOST} machines.txt | cut -d " " -f 4)
  sed "s|SUBNET|$SUBNET|g" \
    configs/10-bridge.conf > 10-bridge.conf

  sed "s|SUBNET|$SUBNET|g" \
    configs/kubelet-config.yaml > kubelet-config.yaml

  scp 10-bridge.conf kubelet-config.yaml \
  root@${HOST}:~/
done
```

```bash
for HOST in node-0 node-1; do
  scp \
    downloads/worker/* \
    downloads/client/kubectl \
    configs/99-loopback.conf \
    configs/containerd-config.toml \
    configs/kube-proxy-config.yaml \
    units/containerd.service \
    units/kubelet.service \
    units/kube-proxy.service \
    root@${HOST}:~/
done
```

```bash
for HOST in node-0 node-1; do
  ssh root@${HOST} "mkdir -p ~/cni-plugins"

  scp \
    downloads/cni-plugins/* \
    root@${HOST}:~/cni-plugins/
done
```

Verify each worker received the required files:

```bash
for HOST in node-0 node-1; do
  ssh root@${HOST} "
    test -f crictl
    test -f containerd
    test -f containerd-shim-runc-v2
    test -f containerd-stress
    test -f kubelet
    test -f kube-proxy
    test -f runc
    test -f cni-plugins/bridge
    test -f cni-plugins/host-local
    test -f cni-plugins/loopback
    test -f containerd-config.toml
    test -f kubelet-config.yaml
    test -f kube-proxy-config.yaml
    test -f containerd.service
    test -f kubelet.service
    test -f kube-proxy.service
  "
done
```

Verify each worker can resolve and reach the Kubernetes API server hostname before starting the kubelet:

```bash
for HOST in node-0 node-1; do
  ssh root@${HOST} "
    getent hosts server.kubernetes.local
    curl --cacert /var/lib/kubelet/ca.crt \
      https://server.kubernetes.local:6443/version
  "
done
```

If hostname resolution fails, return to the [Provisioning Compute Resources](03-compute-resources.md) lab and re-run the host lookup table steps that append the `hosts` file to each remote machine. The kubelet uses `server.kubernetes.local` from its kubeconfig, so worker registration will fail until that name resolves on every worker node.

The commands in the next section must be run on each worker instance: `node-0`, `node-1`. Login to the worker instance using the `ssh` command. Example:

```bash
ssh root@node-0
```

## Provisioning a Kubernetes Worker Node

Install the OS dependencies:

```bash
{
  apt-get update
  apt-get -y install socat conntrack ipset kmod
}
```

> The socat binary enables support for the `kubectl port-forward` command.

Disable Swap

Kubernetes has limited support for the use of swap memory, as it is difficult to provide guarantees and account for pod memory utilization when swap is involved.

Verify if swap is disabled:

```bash
swapon --show
```

If output is empty then swap is disabled. If swap is enabled run the following command to disable swap immediately:

```bash
swapoff -a
```

> To ensure swap remains off after reboot consult your Linux distro documentation.

Create the installation directories:

```bash
mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

Install the worker binaries:

```bash
{
  mv crictl kube-proxy kubelet runc \
    /usr/local/bin/
  mv containerd containerd-shim-runc-v2 containerd-stress /bin/
  mv cni-plugins/* /opt/cni/bin/
}
```

### Configure CNI Networking

Create the `bridge` network configuration file:

```bash
mv 10-bridge.conf 99-loopback.conf /etc/cni/net.d/
```

To ensure network traffic crossing the CNI `bridge` network is processed by `iptables`, load and configure the `br-netfilter` kernel module:

```bash
{
  modprobe br-netfilter
  echo "br-netfilter" >> /etc/modules-load.d/modules.conf
}
```

```bash
{
  echo "net.bridge.bridge-nf-call-iptables = 1" \
    >> /etc/sysctl.d/kubernetes.conf
  echo "net.bridge.bridge-nf-call-ip6tables = 1" \
    >> /etc/sysctl.d/kubernetes.conf
  sysctl -p /etc/sysctl.d/kubernetes.conf
}
```

### Configure containerd

Install the `containerd` configuration files:

```bash
{
  mkdir -p /etc/containerd/
  mv containerd-config.toml /etc/containerd/config.toml
  mv containerd.service /etc/systemd/system/
}
```

### Configure the Kubelet

Create the `kubelet-config.yaml` configuration file:

```bash
{
  mv kubelet-config.yaml /var/lib/kubelet/
  mv kubelet.service /etc/systemd/system/
}
```

### Configure the Kubernetes Proxy

```bash
{
  mv kube-proxy-config.yaml /var/lib/kube-proxy/
  mv kube-proxy.service /etc/systemd/system/
}
```

### Start the Worker Services

```bash
{
  systemctl daemon-reload
  systemctl enable containerd kubelet kube-proxy
  systemctl start containerd kubelet kube-proxy
}
```

Check if the kubelet service is running:

```bash
systemctl is-active kubelet
```

```text
active
```

Be sure to complete the steps in this section on each worker node, `node-0` and `node-1`, before moving on to the next section.

## Verification

Run the following commands from the `jumpbox` machine.

List the registered Kubernetes nodes:

```bash
ssh root@server \
  "kubectl get nodes \
  --kubeconfig admin.kubeconfig"
```

```
NAME     STATUS   ROLES    AGE    VERSION
node-0   Ready    <none>   1m     v1.36.0
node-1   Ready    <none>   10s    v1.36.0
```

If no nodes are returned, check whether the kubelets can resolve and reach the API server:

```bash
for host in node-0 node-1; do
  ssh root@${host} "
    getent hosts server.kubernetes.local
    curl --cacert /var/lib/kubelet/ca.crt \
      https://server.kubernetes.local:6443/version
    journalctl -u kubelet --no-pager -n 40
  "
done
```

Next: [Configuring kubectl for Remote Access](10-configuring-kubectl.md)
