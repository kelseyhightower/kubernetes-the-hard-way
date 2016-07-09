# Deploying the Cluster DNS Add-on

In this lab you will deploy the DNS add-on which is required for every Kubernetes cluster. Without the DNS add-on the following things will not work:

* DNS based service discovery 
* DNS lookups from containers running in pods

## Cluster DNS Add-on

### Create the `skydns` service:

```
kubectl create -f https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/master/skydns-svc.yaml
```

#### Verification

```
kubectl --namespace=kube-system get svc
```
```
NAME       CLUSTER-IP   EXTERNAL-IP   PORT(S)         AGE
kube-dns   10.32.0.10   <none>        53/UDP,53/TCP   1m
```

### Create the `skydns` replication controller:

```
kubectl create -f https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/master/skydns-rc.yaml
```

#### Verification

```
kubectl --namespace=kube-system get pods
```
```
NAME                 READY     STATUS    RESTARTS   AGE
kube-dns-v18-79maa   3/3       Running   0          41s
kube-dns-v18-bcs1f   3/3       Running   0          41s
```