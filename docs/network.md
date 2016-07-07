# Managing the Container Network Routes

## Get the routing Table

```
kubectl get nodes \
--output=jsonpath='{range .items[*]}{.name} {.status.addaddress} {.spec.podCIDR} {"\n"}{end}'
```

```
10.240.0.30 10.200.0.0/24
```

### Add the routes

```
gcloud compute routes create default-route-10-200-0-0-24 \
  --next-hop-address 10.240.0.30 \
  --destination-range 10.200.0.0/24
```