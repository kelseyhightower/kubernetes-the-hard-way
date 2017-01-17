#!/usr/bin/bash
set -x

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes \
  --format 'value(address)')

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

kubectl config set-credentials admin --token chAng3m3

kubectl config set-context default-context \
  --cluster=kubernetes-the-hard-way \
  --user=admin \
  --namespace=""

kubectl config use-context default-context
kubectl get componentstatuses
kubectl get nodes
