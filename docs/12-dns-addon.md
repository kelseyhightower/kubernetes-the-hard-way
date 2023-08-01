# Deploying the DNS Cluster Add-on

In this lab you will deploy the [DNS add-on](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) which provides DNS based service discovery, backed by [CoreDNS](https://github.com/coredns/coredns), to applications running inside the Kubernetes cluster.

## The DNS Cluster Add-on

Deploy the `coredns` cluster add-on:

```
kubectl apply --filename ./manifests/coredns-1.10.1.yaml
```

> output

```
serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
service/kube-dns created
deployment.apps/coredns created
```

List the pods created by the `kube-dns` deployment:

```
kubectl get pods --namespace kube-system --selector k8s-app=kube-dns
```

> output

```
NAME                       READY   STATUS    RESTARTS   AGE
coredns-8494f9c688-hh7r2   1/1     Running   0          10s
coredns-8494f9c688-zqrj2   1/1     Running   0          10s
```

## Verification

Create a `busybox` pod:

```
kubectl run busybox --image busybox:1.36.1 --command -- sleep infinity
```

List the pod created:

```
kubectl get pods --selector run=busybox
```

> output

```
NAME      READY   STATUS    RESTARTS   AGE
busybox   1/1     Running   0          3s
```

Retrieve the full name of the `busybox` pod:

```
POD_NAME=$(kubectl get pods --selector run=busybox \
  --output jsonpath="{.items[0].metadata.name}")
```

Execute a DNS lookup for the `kubernetes` service inside the `busybox` pod:

```
kubectl exec --stdin --tty "${POD_NAME}" -- nslookup kubernetes
```

> output

```
Server:    10.32.0.10
Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local
```

Delete the `busybox` pod:

```
kubectl delete pod "${POD_NAME}"
```

Next: [Smoke Test](./13-smoke-test.md)
