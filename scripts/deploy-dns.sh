#!/usr/bin/bash
set -x

kubectl create -f https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/master/services/kubedns.yaml

kubectl --namespace=kube-system get svc

kubectl create -f https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/master/deployments/kubedns.yaml

kubectl --namespace=kube-system get pods
