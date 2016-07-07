# Managing the Container Network Routes

Now that each worker node is online we need to add routes to make sure that Pods running on different machines can talk to each other. In this lab we are not going to provision any overlay networks and instead rely on layer 3 networking. That means we need to add routes to our route. In GCP each network has a route that can be configured. If this was an on-prem datacenter then ideally you would need to add the routes to your router.

After completing this lab you will have the following router entries:

```
$ gcloud compute routes list
```
```
NAME                            NETWORK  DEST_RANGE     NEXT_HOP                  PRIORITY
default-route-10-200-0-0-24     default  10.200.0.0/24  10.240.0.30               1000
default-route-10-200-1-0-24     default  10.200.1.0/24  10.240.0.31               1000
default-route-10-200-2-0-24     default  10.200.2.0/24  10.240.0.32               1000
```

## Get the routing Table

The first thing we need to do is gather the information required to populate the router table. We need the Internal IP address and Pod Subnet for each of the worker nodes.

```
gcloud compute ssh controller0
```

Use `kubectl` to print the `InternalIP` and `podCIDR` for each worker node:

```
kubectl get nodes \
  --output=jsonpath='{range .items[*]}{.status.addresses[?(@.type=="InternalIP")].address} {.spec.podCIDR} {"\n"}{end}'
```

Output:

```
10.240.0.30 10.200.0.0/24 
10.240.0.31 10.200.1.0/24 
10.240.0.32 10.200.2.0/24 
```

Use `gcloud` to add the routes to GCP:

```
gcloud compute routes create default-route-10-200-0-0-24 \
  --next-hop-address 10.240.0.30 \
  --destination-range 10.200.0.0/24
```

```
gcloud compute routes create default-route-10-200-1-0-24 \
  --next-hop-address 10.240.0.31 \
  --destination-range 10.200.1.0/24
```

```
gcloud compute routes create default-route-10-200-2-0-24 \
  --next-hop-address 10.240.0.32 \
  --destination-range 10.200.2.0/24
```