#!/usr/bin/bash
set -x

if [[ -z ${NUM_CONTROLLERS} || -z ${NUM_WORKERS} ]]; then
    echo "Must set NUM_CONTROLLERS and NUM_WORKERS environment variables"
    exit 1
fi

(( NUM_CONTROLLERS-- ))
(( NUM_WORKERS-- ))

for i in $(eval echo "{0..${NUM_CONTROLLERS}}"); do
    INITIAL_CLUSTER="${INITIAL_CLUSTER}controller${i}=https://10.240.0.1${i}:2380,"
done

INITIAL_CLUSTER=$(echo ${INITIAL_CLUSTER} | sed 's/,$//')

for i in $(eval echo "{0..${NUM_CONTROLLERS}}"); do
    gcloud compute ssh controller${i} --command "sudo mkdir -p /etc/etcd/"

    gcloud compute ssh controller${i} --command "sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/"

    gcloud compute ssh controller${i} --command "wget https://github.com/coreos/etcd/releases/download/v3.0.10/etcd-v3.0.10-linux-amd64.tar.gz"

    gcloud compute ssh controller${i} --command "tar -xvf etcd-v3.0.10-linux-amd64.tar.gz"

    gcloud compute ssh controller${i} --command "sudo mv etcd-v3.0.10-linux-amd64/etcd* /usr/bin/"

    gcloud compute ssh controller${i} --command "sudo mkdir -p /var/lib/etcd"

    INTERNAL_IP=$(gcloud compute ssh controller${i} --command 'curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip')

    gcloud compute ssh controller${i} --command "echo '[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/bin/etcd --name controller${i} \
  --cert-file=/etc/etcd/kubernetes.pem \
  --key-file=/etc/etcd/kubernetes-key.pem \
  --peer-cert-file=/etc/etcd/kubernetes.pem \
  --peer-key-file=/etc/etcd/kubernetes-key.pem \
  --trusted-ca-file=/etc/etcd/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ca.pem \
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \
  --listen-peer-urls https://${INTERNAL_IP}:2380 \
  --listen-client-urls https://${INTERNAL_IP}:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://${INTERNAL_IP}:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster ${INITIAL_CLUSTER} \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target' > etcd.service"

    gcloud compute ssh controller${i} --command "cat etcd.service"
    gcloud compute ssh controller${i} --command "sudo mv etcd.service /etc/systemd/system/"
    gcloud compute ssh controller${i} --command "sudo systemctl daemon-reload"
    gcloud compute ssh controller${i} --command "sudo systemctl enable etcd"
    gcloud compute ssh controller${i} --command "sudo systemctl start etcd"
    gcloud compute ssh controller${i} --command "sudo systemctl status etcd --no-pager"
done

gcloud compute ssh controller${i} --command "etcdctl --ca-file=/etc/etcd/ca.pem cluster-health"
