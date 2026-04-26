#!/usr/bin/env bash
set -euo pipefail

kubectl version
kubectl get nodes -o wide
kubectl -n kube-system get pods
kubectl get --raw='/readyz?verbose'

if kubectl -n kube-system get deployment coredns >/dev/null 2>&1; then
  kubectl -n kube-system rollout status deployment/coredns
fi
