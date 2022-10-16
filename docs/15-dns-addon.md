# Deploying the DNS Cluster Add-on

In this lab you will deploy the [DNS add-on](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) which provides DNS based service discovery, backed by [CoreDNS](https://coredns.io/), to applications running inside the Kubernetes cluster.

## The DNS Cluster Add-on

[//]: # (host:master-1)

Deploy the `coredns` cluster add-on:

Note that if you have [changed the service CIDR range](./01-prerequisites.md#service-network) and thus this file, you will need to save your copy onto `master-1` (paste to vi, then save) and apply that.

```bash
kubectl apply -f https://raw.githubusercontent.com/mmumshad/kubernetes-the-hard-way/master/deployments/coredns.yaml
```

> output

```
serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
deployment.extensions/coredns created
service/kube-dns created
```

List the pods created by the `kube-dns` deployment:

[//]: # (command:kubectl wait deployment -n kube-system coredns --for condition=Available=True --timeout=90s)

```bash
kubectl get pods -l k8s-app=kube-dns -n kube-system
```

> output

```
NAME                       READY   STATUS    RESTARTS   AGE
coredns-699f8ddd77-94qv9   1/1     Running   0          20s
coredns-699f8ddd77-gtcgb   1/1     Running   0          20s
```

Reference: https://kubernetes.io/docs/tasks/administer-cluster/coredns/#installing-coredns

## Verification

Create a `busybox` pod:

```bash
kubectl run busybox --image=busybox:1.28 --command -- sleep 3600
```

[//]: # (command:kubectl wait pods -n default -l run=busybox --for condition=Ready --timeout=90s)


List the pod created by the `busybox` pod:

```bash
kubectl get pods -l run=busybox
```

> output

```
NAME                      READY   STATUS    RESTARTS   AGE
busybox-bd8fb7cbd-vflm9   1/1     Running   0          10s
```

Execute a DNS lookup for the `kubernetes` service inside the `busybox` pod:

```bash
kubectl exec -ti busybox -- nslookup kubernetes
```

> output

```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
```

Prev: [Kube API Server to Kubelet Connectivity](14-kube-apiserver-to-kubelet.md)</br>
Next: [Smoke Test](16-smoke-test.md)
