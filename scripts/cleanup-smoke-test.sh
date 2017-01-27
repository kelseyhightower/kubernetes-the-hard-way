#!/usr/bin/env bash
set -x

kubectl delete deployment nginx
kubectl delete svc nginx
gcloud -q compute firewall-rules delete kubernetes-nginx-service
