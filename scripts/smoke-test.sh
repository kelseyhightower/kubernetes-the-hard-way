#!/usr/bin/bash
set -x

kubectl run nginx --image=nginx --port=80 --replicas=3

kubectl get pods -o wide

sleep 10

kubectl expose deployment nginx --type NodePort

NODE_PORT=$(kubectl get svc nginx --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

gcloud compute firewall-rules create kubernetes-nginx-service \
  --allow=tcp:${NODE_PORT} \
  --network kubernetes

NODE_PUBLIC_IP=$(gcloud compute instances describe worker0 \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

curl http://${NODE_PUBLIC_IP}:${NODE_PORT}
