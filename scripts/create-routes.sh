#!/usr/bin/bash
set -x

if [[ -z ${NUM_CONTROLLERS} || -z ${NUM_WORKERS} || -z ${KUBERNETES_VERSION} ]]; then
    echo "Must set NUM_CONTROLLERS, NUM_WORKERS and KUBERNETES_VERSION (e.g. 'vX.Y.Z') environment variables"
    exit 1
fi

(( NUM_CONTROLLERS-- ))
(( NUM_WORKERS-- ))

for i in $(eval echo "{0..${NUM_WORKERS}}"); do
    gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
      --network kubernetes \
      --next-hop-address 10.240.0.2${i} \
      --destination-range 10.200.${i}.0/24
done
