# Cluster DNS

Kubernetes workloads expect cluster DNS to resolve Services and Pods. The kubelet configuration in this repo points Pods at the DNS Service IP `10.32.0.10`, which lives inside the Service CIDR `10.32.0.0/24`.

This lab deploys CoreDNS after networking is functional.

## Deploy CoreDNS

Run the following from the `jumpbox`:

```bash
kubectl apply -f configs/coredns.yaml
```

Wait for CoreDNS to become ready:

```bash
kubectl -n kube-system rollout status deployment/coredns
```

## Verification

Start a temporary Pod and resolve the default Kubernetes Service:

```bash
kubectl run dns-test \
  --image=busybox:stable \
  --restart=Never \
  --command -- sleep 3600
```

Wait for the Pod:

```bash
kubectl wait pod/dns-test \
  --for=condition=Ready \
  --timeout=120s
```

Run a lookup:

```bash
kubectl exec dns-test -- nslookup kubernetes.default.svc.cluster.local
```

You should see an address in the Service CIDR. In this tutorial, the API server Service should resolve to `10.32.0.1`.

Clean up:

```bash
kubectl delete pod dns-test
```

## Troubleshooting

Check the CoreDNS Pods:

```bash
kubectl -n kube-system get pods -l k8s-app=kube-dns
```

Check the CoreDNS Service:

```bash
kubectl -n kube-system get svc kube-dns
```

Review logs:

```bash
kubectl -n kube-system logs deployment/coredns
```

If DNS fails, verify Pod networking first. DNS is one of the first workloads to reveal CNI or Service routing issues.

Next: [Smoke Test](14-smoke-test.md)
