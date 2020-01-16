# Deploying the DNS Cluster Add-on

In this lab you will deploy the [DNS add-on](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) which provides DNS based service discovery, backed by [CoreDNS](https://coredns.io/), to applications running inside the Kubernetes cluster.

## The DNS Cluster Add-on

First check registered worker nodes:

```
$ kubectl get nodes -o wide
NAME       STATUS   ROLES    AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION    CONTAINER-RUNTIME
worker-0   Ready    <none>   26h   v1.15.3   10.240.0.20   <none>        Ubuntu 18.04.3 LTS   4.15.0-1051-aws   containerd://1.2.9
worker-1   Ready    <none>   26h   v1.15.3   10.240.0.21   <none>        Ubuntu 18.04.3 LTS   4.15.0-1051-aws   containerd://1.2.9
worker-2   Ready    <none>   26h   v1.15.3   10.240.0.22   <none>        Ubuntu 18.04.3 LTS   4.15.0-1051-aws   containerd://1.2.9
```

Deploy the `coredns` cluster add-on:

```
$ kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns.yaml

serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
deployment.extensions/coredns created
service/kube-dns created
```

List the pods created by the `kube-dns` deployment:

```
$ kubectl get pods -l k8s-app=kube-dns -n kube-system -o wide

NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
coredns-5fb99965-gk2j7   1/1     Running   0          98s   10.200.1.3   worker-1   <none>           <none>
coredns-5fb99965-w6hxj   1/1     Running   0          98s   10.200.2.3   worker-2   <none>           <none>
```

Note that pods are running in pre-defined POD CIDR range. Your results may differ as we've not specified on which worker node each pod should run.


## Verification

Create a `busybox` deployment:

```
$ kubectl run --generator=run-pod/v1 busybox --image=busybox:1.28 --command -- sleep 3600

pod/busybox created
```

List the pod created by the `busybox` deployment:

```
$ kubectl get pods -l run=busybox -o wide

NAME      READY   STATUS    RESTARTS   AGE     IP           NODE       NOMINATED NODE   READINESS GATES
busybox   1/1     Running   0          3m45s   10.200.2.2   worker-2   <none>           <none>
```

Retrieve the full name of the `busybox` pod:

```
$ POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
```

Execute a DNS lookup for the `kubernetes` service inside the `busybox` pod:

```
$ kubectl exec -ti $POD_NAME -- nslookup kubernetes

Server:    10.32.0.10
Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local
```

Next: [Smoke Test](13-smoke-test.md)