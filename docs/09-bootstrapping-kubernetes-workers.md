# Bootstrapping the Kubernetes Worker Nodes

In this lab you will bootstrap two Kubernetes worker nodes. The following
components will be installed: [runc], [container networking plugins],
[containerd], [kubelet], and [kube-proxy].

## Prerequisites

The commands in this section must be run from the `jumpbox`.

Copy the Kubernetes binaries and systemd unit files to each worker instance:

```bash
for HOST in node01 node02; do
  # Grab the subnet CIDR block from the machines database, if you want to use
  SUBNET=$(grep ${HOST} machines.txt | cut -d " " -f 4)

  # For each machine set its subnet in the CNI config file
  sed "s|SUBNET|${SUBNET}|g" \
    configs/11-crio-ipv4-bridge.conflist > 11-crio-ipv4-bridge.conflist

  # Copy the CNI network plugin config over
  scp 11-crio-ipv4-bridge.conflist vagrant@${HOST}:~/

  # Copy binaries over
  scp \
    downloads/worker/* \
    downloads/client/kubectl \
    configs/99-loopback.conf \
    configs/containerd-config.toml \
    configs/kube-proxy-config.yaml \
    configs/kubelet-config.yaml \
    units/containerd.service \
    units/kubelet.service \
    units/kube-proxy.service \
    downloads/cni-plugins/ \
    11-crio-ipv4-bridge.conflist \
    vagrant@${HOST}:~/

  # Copy CNI plugins directory over
  scp -r \
    downloads/cni-plugins/ \
    vagrant@${HOST}:~/
done
```

Create the installation directories:

```bash
for HOST in node01 node02
    ssh vagrant@${HOST} sudo mkdir -p \
      /etc/cni/net.d \
      /opt/cni/bin \
      /var/lib/kubelet \
      /var/lib/kube-proxy \
      /var/lib/kubernetes \
      /var/run/kubernetes \
      /etc/containerd
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
sudo mv 11-crio-ipv4-bridge.conflist 99-loopback.conf /etc/cni/net.d/
```

To ensure network traffic crossing the CNI `bridge` network is processed by
`iptables`, load and configure the `br-netfilter` kernel module:

```bash
{
  sudo modprobe br-netfilter
  echo "br-netfilter" | sudo tee -a /etc/modules-load.d/modules.conf
}
```

Enable for IPv4 and IPv6 (a.k.a dual-stack), then load (with `sysctl -p`) in
sysctl settings from the file specified.

```bash
{
  echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee -a /etc/sysctl.d/kubernetes.conf
  echo "net.bridge.bridge-nf-call-ip6tables = 1" | sudo tee -a /etc/sysctl.d/kubernetes.conf
  # Load in sysctl settings from the file specified
  sudo sysctl -p /etc/sysctl.d/kubernetes.conf
}
```

### Configure containerd, Kubelet, and the Kubernetes Proxy

Install the configuration files:

```bash
{
  sudo mv containerd-config.toml /etc/containerd/config.toml
  sudo mv kubelet-config.yaml /var/lib/kubelet/
  sudo mv kube-proxy-config.yaml /var/lib/kube-proxy/

  sudo mv containerd.service kubelet.service kube-proxy.service \
    /etc/systemd/system/
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

NOTE: For extra credit, see if you can also turn the controlplnae into a
worker node that can host PODs. Hint: you need to give it a subnet such as
`10.200.2.0/24` in the machines.txt

Next: [Configuring kubectl for Remote Access](10-configuring-kubectl.md)

---

[runc]: https://github.com/opencontainers/runc
[container networking plugins]: https://github.com/containernetworking/cni
[containerd]: https://github.com/containerd/containerd
[kubelet]: https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet
[kube-proxy]: https://kubernetes.io/docs/concepts/cluster-administration/proxies
