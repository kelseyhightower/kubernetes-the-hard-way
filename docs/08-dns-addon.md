# Deploying the DNS Add-on

In this lab you will deploy the DNS add-on which is required for every Kubernetes cluster. Without the DNS add-on the following things will not work:

* DNS based service discovery 
* DNS lookups from containers running in pods

## Deploy the Cluster DNS Add-on

```
kubectl create -f https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/master/skydns-svc.yaml
```

```
kubectl create -f https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/master/skydns-rc.yaml
```