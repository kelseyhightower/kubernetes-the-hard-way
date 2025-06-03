# Bootstrapping the Kubernetes Worker Nodes

In this lab you will bootstrap two Kubernetes worker nodes. The following
components will be installed: [runc], [container networking plugins],
[containerd], [kubelet], and [kube-proxy].

## Prerequisites

The commands in this section must be run from the `jumpbox`.

Copy the Kubernetes binaries and systemd unit files to each worker instance:

```bash
for HOST in node01 node02; do
  SUBNET=$(grep ${HOST} machines.txt | cut -d " " -f 4)
  sed "s|SUBNET|$SUBNET|g" \
    configs/10-bridge.conf > 10-bridge.conf

  scp 10-bridge.conf configs/kubelet-config.yaml \
  vagrant@${HOST}:~/
done
```

```bash
for HOST in node01 node02; do
  scp \
    downloads/worker/* \
    downloads/client/kubectl \
    configs/99-loopback.conf \
    configs/containerd-config.toml \
    configs/kube-proxy-config.yaml \
    units/containerd.service \
    units/kubelet.service \
    units/kube-proxy.service \
    downloads/cni-plugins/ \
    vagrant@${HOST}:~/
done
```

```bash
for HOST in node01 node02; do
  scp -r \
    downloads/cni-plugins/ \
    vagrant@${HOST}:~/cni-plugins/
done
```

The commands in the next section must be run on each worker instance: `node01`,
`node02`. Login to the worker instance using the `ssh` command. Example:

```bash
ssh vagrant@node01
```

## Provisioning a Kubernetes Worker Node

Install the OS dependencies:

```bash
{
  sudo apt-get update
  sudo apt-get -y install socat conntrack ipset kmod
}
```

> The socat binary enables support for the `kubectl port-forward` command.

Disable Swap

Kubernetes has limited support for the use of swap memory, as it is difficult
to provide guarantees and account for pod memory utilization when swap is
involved.

Verify if swap is disabled:

```bash
swapon --show
```

If output is empty then swap is disabled. If swap is enabled run the following
command to disable swap immediately:

```bash
swapoff -a
```

> To ensure swap remains off after reboot consult your Linux distro
> documentation.

Create the installation directories:

```bash
sudo mkdir -p \
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
  sudo mv crictl kube-proxy kubelet kubectl /usr/local/bin/
  sudo mv runc /usr/local/sbin/
  sudo mv containerd ctr containerd-shim-runc-v2 containerd-stress /bin/
  sudo mv cni-plugins/* /opt/cni/bin/
}
```

### Configure CNI Networking

Create the `bridge` network configuration file:

```bash
sudo mv 10-bridge.conf 99-loopback.conf /etc/cni/net.d/
```

To ensure network traffic crossing the CNI `bridge` network is processed by
`iptables`, load and configure the `br-netfilter` kernel module:

```bash
{
  sudo modprobe br-netfilter
  echo "br-netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
}
```

```bash
{
  echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee -a /etc/sysctl.d/kubernetes.conf
  echo "net.bridge.bridge-nf-call-ip6tables = 1" | sudo tee -a /etc/sysctl.d/kubernetes.conf
  sudo sysctl -p /etc/sysctl.d/kubernetes.conf
}
```

### Configure containerd

Install the `containerd` configuration files:

```bash
{
  sudo mkdir -p /etc/containerd/
  sudo mv containerd-config.toml /etc/containerd/config.toml
  sudo mv containerd.service /etc/systemd/system/
}
```

### Configure the Kubelet

Create the `kubelet-config.yaml` configuration file:

```bash
{
  sudo mv kubelet-config.yaml /var/lib/kubelet/
  sudo mv kubelet.service /etc/systemd/system/
}
```

### Configure the Kubernetes Proxy

```bash
{
  sudo mv kube-proxy-config.yaml /var/lib/kube-proxy/
  sudo mv kube-proxy.service /etc/systemd/system/
}
```

### Start the Worker Services

```bash
{
  sudo systemctl daemon-reload
  sudo systemctl enable containerd kubelet kube-proxy
  sudo systemctl start containerd kubelet kube-proxy
}
```

Check if the kubelet service is running:

```bash
sudo systemctl status kubelet
```

```text
● kubelet.service - Kubernetes Kubelet
     Loaded: loaded (/etc/systemd/system/kubelet.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2025-06-03 15:36:24 UTC; 28s ago
       Docs: https://github.com/kubernetes/kubernetes
   Main PID: 5645 (kubelet)
      Tasks: 10 (limit: 1102)
     Memory: 27.8M
        CPU: 501ms
     CGroup: /system.slice/kubelet.service
             └─5645 /usr/local/bin/kubelet --config=/var/lib/kubelet/kubelet-config.yaml --kubeconfig=/var/lib/kubelet/kubeconfig --v=2

Jun 03 15:36:24 node02 kubelet[5645]: I0603 15:36:24.878735    5645 kubelet_node_status.go:687] "Recording event message for node" node="node02" event="NodeHasNoDiskPressure"
Jun 03 15:36:24 node02 kubelet[5645]: I0603 15:36:24.878809    5645 kubelet_node_status.go:687] "Recording event message for node" node="node02" event="NodeHasSufficientPID"
Jun 03 15:36:24 node02 kubelet[5645]: I0603 15:36:24.878879    5645 kubelet_node_status.go:75] "Attempting to register node" node="node02"
Jun 03 15:36:24 node02 kubelet[5645]: I0603 15:36:24.886841    5645 kubelet_node_status.go:78] "Successfully registered node" node="node02"
```

Be sure to complete the steps in this section on each worker node, `node01`
and `node02`, before moving on to the next section.

## Verification

Run the following commands from the `jumpbox` machine.

List the registered Kubernetes nodes:

```bash
ssh vagrant@controlplane \
  "kubectl get nodes \
  --kubeconfig admin.kubeconfig"
```

```
NAME     STATUS   ROLES    AGE     VERSION
node01   Ready    <none>   2m5s    v1.33.1
node02   Ready    <none>   2m12s   v1.33.1
```

Next: [Configuring kubectl for Remote Access](10-configuring-kubectl.md)

---

[runc]: https://github.com/opencontainers/runc
[container networking plugins]: https://github.com/containernetworking/cni
[containerd]: https://github.com/containerd/containerd
[kubelet]: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet
[kube-proxy]: https://kubernetes.io/docs/concepts/cluster-administration/proxies
