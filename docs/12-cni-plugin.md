# Modern CNI Plugin

The previous lab used manual routes to make Pod-to-Pod traffic work across nodes. That is useful for learning, but modern clusters normally delegate this job to a CNI plugin.

This lab keeps the bridge CNI path available and introduces a modern CNI track. Cilium is used as the reference because it teaches the current direction of Kubernetes networking: eBPF datapaths, network policy, service handling, and built-in observability. Calico or another CNI can be substituted if it better matches your environment.

## Keep The Manual Route Path

If your goal is to understand Linux routing and the Kubernetes networking model from first principles, keep the manual routes from the previous lab and continue to the DNS lab.

This path uses:

```text
configs/10-bridge.conf
configs/99-loopback.conf
docs/11-pod-network-routes.md
```

## Use A Managed CNI Path

If your goal is to model a current cluster, remove the manual route dependency and install a CNI plugin after the control plane is running and before scheduling real workloads.

From the `jumpbox`, install the Cilium CLI:

```bash
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all \
  "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz"
tar -xzf cilium-linux-${CLI_ARCH}.tar.gz
install -m 0755 cilium /usr/local/bin/cilium
```

Install Cilium into the cluster:

```bash
cilium install \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=false
```

Check status:

```bash
cilium status --wait
```

Run the connectivity test when the cluster can pull test images:

```bash
cilium connectivity test
```

## When To Disable kube-proxy

This repo still installs kube-proxy because it keeps the base architecture easy to compare with the upstream Kubernetes component model. Once the CNI path is understood, an advanced extension is to let Cilium replace kube-proxy:

```bash
cilium install \
  --set ipam.mode=kubernetes \
  --set kubeProxyReplacement=true
```

When doing that, remove or disable `kube-proxy.service` on the workers and avoid applying `configs/kube-proxy-config.yaml`.

## Design Notes

- Manual routes are transparent but not resilient.
- Bridge CNI is small and understandable but does not provide network policy.
- Cilium and Calico are closer to modern production practice.
- Pick one networking path per cluster. Mixing manual routes and a full CNI plugin makes debugging harder.

Next: [Cluster DNS](13-dns.md)
