#!/usr/bin/env bash
kubectl certificate approve --kubeconfig admin.kubeconfig $(kubectl get csr --kubeconfig admin.kubeconfig -o json | jq -r '.items | .[]  | select(.spec.username == "system:node:node02") | .metadata.name')
