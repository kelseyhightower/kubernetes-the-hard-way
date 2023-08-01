# Cleaning Up

In this lab you will delete the compute resources and optionally the files and configurations created during this tutorial.

## Compute Instances

Delete the controller and worker compute instances:

```
gcloud compute instances delete \
  controller-0 controller-1 controller-2 \
  worker-0 worker-1 worker-2 \
  --quiet
```

## Networking

Delete the external load balancer network resources:

```
gcloud compute forwarding-rules delete kubernetes-forwarding-rule --quiet

gcloud compute target-pools delete kubernetes-target-pool --quiet

gcloud compute http-health-checks delete kubernetes --quiet

gcloud compute addresses delete kubernetes-the-hard-way --quiet
```

Delete the `kubernetes-the-hard-way` firewall rules:

```
gcloud compute firewall-rules delete \
  kubernetes-the-hard-way-allow-external \
  kubernetes-the-hard-way-allow-health-check \
  kubernetes-the-hard-way-allow-internal \
  kubernetes-the-hard-way-allow-nginx-service \
  --quiet
```

Delete the `kubernetes-the-hard-way` network VPC:

```
gcloud compute routes delete \
    kubernetes-route-10-200-0-0-24 \
    kubernetes-route-10-200-1-0-24 \
    kubernetes-route-10-200-2-0-24 \
    --quiet

gcloud compute networks subnets delete kubernetes --quiet

gcloud compute networks delete kubernetes-the-hard-way --quiet
```

## Cleanup The Admin Kubernetes Configuration File

```
kubectl config unset current-context

kubectl config delete-context kubernetes-the-hard-way

kubectl config delete-user admin

kubectl config delete-cluster kubernetes-the-hard-way
```

## Cleanup the Client Tools

```
sudo rm -i /usr/local/bin/cfssl \
  /usr/local/bin/cfssljson \
  /usr/local/bin/kubectl
```
