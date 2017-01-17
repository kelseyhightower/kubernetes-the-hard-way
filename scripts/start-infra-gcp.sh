#!/usr/bin/bash
set -x

if [[ -z ${NUM_CONTROLLERS} || -z ${NUM_WORKERS} ]]; then
    echo "Must set NUM_CONTROLLERS and NUM_WORKERS env vars"
    exit 1
fi

(( NUM_CONTROLLERS-- ))
(( NUM_WORKERS-- ))

gcloud compute networks create kubernetes --mode custom

gcloud compute networks subnets create kubernetes \
  --network kubernetes \
  --range 10.240.0.0/24

gcloud compute firewall-rules create kubernetes-allow-icmp \
  --allow icmp \
  --network kubernetes \
  --source-ranges 0.0.0.0/0

gcloud compute firewall-rules create kubernetes-allow-internal \
  --allow tcp:0-65535,udp:0-65535,icmp \
  --network kubernetes \
  --source-ranges 10.240.0.0/24

gcloud compute firewall-rules create kubernetes-allow-rdp \
  --allow tcp:3389 \
  --network kubernetes \
  --source-ranges 0.0.0.0/0

gcloud compute firewall-rules create kubernetes-allow-ssh \
  --allow tcp:22 \
  --network kubernetes \
  --source-ranges 0.0.0.0/0

gcloud compute firewall-rules create kubernetes-allow-healthz \
  --allow tcp:8080 \
  --network kubernetes \
  --source-ranges 130.211.0.0/22

gcloud compute firewall-rules create kubernetes-allow-api-server \
  --allow tcp:6443 \
  --network kubernetes \
  --source-ranges 0.0.0.0/0

gcloud compute firewall-rules list --filter "network=kubernetes"

gcloud compute addresses create kubernetes --region=us-west1

gcloud compute addresses list kubernetes

# Kubernetes controller
for i in $(eval echo "{0..${NUM_CONTROLLERS}}"); do
    gcloud compute instances create controller${i} \
     --boot-disk-size 200GB \
     --can-ip-forward \
     --image ubuntu-1604-xenial-v20160921 \
     --image-project ubuntu-os-cloud \
     --machine-type n1-standard-1 \
     --private-network-ip 10.240.0.1${i} \
     --subnet kubernetes
done

# Kubernetes workers
for i in $(eval echo "{0..${NUM_WORKERS}}"); do
    gcloud compute instances create worker${i} \
     --boot-disk-size 200GB \
     --can-ip-forward \
     --image ubuntu-1604-xenial-v20160921 \
     --image-project ubuntu-os-cloud \
     --machine-type n1-standard-2 \
     --private-network-ip 10.240.0.2${i} \
     --subnet kubernetes
done
