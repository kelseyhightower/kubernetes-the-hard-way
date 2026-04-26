# Upgrades

Upgrades are part of the architecture. A cluster that cannot be upgraded safely is not really finished.

This repo now tracks Kubernetes `v1.36.0`. Kubernetes supports version skew between components, but upgrades should still be planned in a controlled order.

## Recommended Order

1. Read the release notes for the target Kubernetes minor version.
2. Back up etcd.
3. Upgrade the API server.
4. Upgrade controller manager and scheduler.
5. Upgrade kubelet and kube-proxy on workers one node at a time.
6. Upgrade CNI and DNS add-ons.
7. Run smoke tests.

## Control Plane

Replace the binaries on `server`:

```bash
systemctl stop kube-apiserver kube-controller-manager kube-scheduler
mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

Check the API server:

```bash
kubectl version
kubectl get --raw='/readyz?verbose'
```

## Workers

Drain one node:

```bash
kubectl drain node-0 \
  --ignore-daemonsets \
  --delete-emptydir-data
```

Upgrade binaries and restart services on that node:

```bash
systemctl stop kubelet kube-proxy containerd
mv crictl kube-proxy kubelet runc /usr/local/bin/
mv containerd containerd-shim-runc-v2 containerd-stress /bin/
systemctl start containerd kubelet kube-proxy
```

Uncordon the node:

```bash
kubectl uncordon node-0
```

Repeat for each worker.

## What To Watch

- API server readiness
- node readiness
- CNI health
- CoreDNS readiness
- `kubectl get events -A`
- kubelet logs with `journalctl -u kubelet`
- container runtime logs with `journalctl -u containerd`

Next: [Troubleshooting](18-troubleshooting.md)
