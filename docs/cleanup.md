# Cleaning Up

## Virtual Machines

```
gcloud compute instances delete \
  controller0 controller1 controller2 \
  worker0 worker1 worker2 \
  etcd0 etcd1 etcd2
```

## Networking


```
gcloud compute forwarding-rules delete kubernetes-rule
```

```
gcloud compute addresses delete kubernetes
```

```
gcloud compute http-health-checks delete kube-apiserver-check
```

```
gcloud compute target-pools delete kubernetes-pool
```

```
gcloud compute firewall-rules delete kubernetes-api-server
```

```
gcloud compute routes delete default-route-10-200-0-0-24
```

```
gcloud compute routes delete default-route-10-200-1-0-24
```

```
gcloud compute routes delete default-route-10-200-2-0-24
```