# Security Hardening

The early labs optimize for learning and repeatability. This lab tightens the same cluster so the security model is closer to current practice.

## SSH

The setup lab enables root SSH to reduce friction. After the cluster is working, create an administrative user with sudo privileges on each machine and disable direct root SSH:

```bash
sed -i \
  's/^#*PermitRootLogin.*/PermitRootLogin no/' \
  /etc/ssh/sshd_config
systemctl restart sshd
```

Keep at least one working non-root SSH session open while changing this setting.

## API Server Audit Policy

Copy the audit policy to the server:

```bash
scp configs/audit-policy.yaml root@server:~/
ssh root@server \
  "mv audit-policy.yaml /var/lib/kubernetes/audit-policy.yaml"
```

Add the following flag to `units/kube-apiserver.service` before starting or restarting the API server:

```text
--audit-policy-file=/var/lib/kubernetes/audit-policy.yaml
```

The service already writes audit logs to `/var/log/audit.log`.

## Pod Security Admission

Use Pod Security Admission labels on namespaces. Start with the built-in `default` namespace in `baseline` mode:

```bash
kubectl label namespace default \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

For application namespaces, prefer `restricted` when your workloads can run without extra privileges:

```bash
kubectl create namespace apps
kubectl label namespace apps \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

## Network Policy

NetworkPolicy requires a CNI plugin that enforces policy. The bridge CNI path does not. If you installed Cilium or Calico, apply a default-deny policy before opening only the traffic your workloads need:

```bash
kubectl apply -f configs/default-deny-network-policy.yaml
```

## etcd

The minimal lab keeps etcd local to the API server. A hardened version should:

- enable peer and client TLS
- restrict client access to the API server identity
- take scheduled snapshots
- keep three voting members for availability

The backup lab covers the snapshot workflow.

## Kubelet

The kubelet config disables anonymous authentication and uses Webhook authorization. Verify those settings on each worker:

```bash
ssh root@node-0 \
  "grep -A8 -E 'authentication|authorization' /var/lib/kubelet/kubelet-config.yaml"
```

## Image And Supply Chain Notes

For a real cluster, add admission controls that enforce:

- non-root workloads
- approved registries
- signed images
- restricted Linux capabilities
- immutable image tags or digest-pinned images

The exact admission stack varies by organization. The key architectural point is that policy belongs at the API boundary, before Pods are persisted and scheduled.

Next: [etcd Backup And Restore](16-etcd-backup-restore.md)
