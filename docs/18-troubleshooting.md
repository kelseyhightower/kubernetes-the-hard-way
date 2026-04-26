# Troubleshooting

Use this lab as a map when something fails. Start from the layer closest to the symptom, then move down.

## API Server

Check process status:

```bash
ssh root@server systemctl status kube-apiserver
```

Check logs:

```bash
ssh root@server journalctl -u kube-apiserver --no-pager
```

Check readiness:

```bash
kubectl get --raw='/readyz?verbose'
```

## etcd

Check status:

```bash
ssh root@server systemctl status etcd
```

List members:

```bash
ssh root@server etcdctl member list
```

Check endpoint health:

```bash
ssh root@server etcdctl endpoint health
```

## Nodes

List nodes:

```bash
kubectl get nodes -o wide
```

Inspect one node:

```bash
kubectl describe node node-0
```

Check kubelet logs:

```bash
ssh root@node-0 journalctl -u kubelet --no-pager
```

## Runtime

Check containerd:

```bash
ssh root@node-0 systemctl status containerd
```

Use `crictl`:

```bash
ssh root@node-0 crictl ps -a
ssh root@node-0 crictl pods
```

## Networking

Check Pod IPs:

```bash
kubectl get pods -A -o wide
```

Check routes on the manual route path:

```bash
ssh root@node-0 ip route
ssh root@node-1 ip route
```

Check CNI files:

```bash
ssh root@node-0 ls -l /etc/cni/net.d /opt/cni/bin
```

## DNS

Check CoreDNS:

```bash
kubectl -n kube-system get pods -l k8s-app=kube-dns
kubectl -n kube-system logs deployment/coredns
```

Run an isolated DNS test:

```bash
kubectl run dns-debug \
  --image=busybox:stable \
  --restart=Never \
  --command -- nslookup kubernetes.default
```

## Events

Events often reveal the first failing layer:

```bash
kubectl get events -A --sort-by=.lastTimestamp
```

Next: [Cleaning Up](19-cleanup.md)
