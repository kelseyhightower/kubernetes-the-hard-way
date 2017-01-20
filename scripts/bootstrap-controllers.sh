#!/usr/bin/bash
set -x

if [[ -z ${NUM_CONTROLLERS} || -z ${NUM_WORKERS} || -z ${KUBERNETES_VERSION} ]]; then
    echo "Must set NUM_CONTROLLERS, NUM_WORKERS and KUBERNETES_VERSION (e.g. 'vX.Y.Z') environment variables"
    exit 1
fi

(( NUM_CONTROLLERS-- ))
(( NUM_WORKERS-- ))

for i in $(eval echo "{0..${NUM_CONTROLLERS}}"); do
    ETCD_SERVERS="${ETCD_SERVERS}https://10.240.0.1${i}:2379,"
done

ETCD_SERVERS=$(echo ${ETCD_SERVERS} | sed 's/,$//')

for i in $(eval echo "{0..${NUM_CONTROLLERS}}"); do
    gcloud compute ssh controller${i} --command "sudo mkdir -p /var/lib/kubernetes"

    gcloud compute ssh controller${i} --command "sudo cp ca.pem kubernetes-key.pem kubernetes.pem /var/lib/kubernetes/"

    gcloud compute ssh controller${i} --command "wget https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kube-apiserver"

    gcloud compute ssh controller${i} --command "wget https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kube-controller-manager"

    gcloud compute ssh controller${i} --command "wget https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kube-scheduler"

    gcloud compute ssh controller${i} --command "wget https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl"

    gcloud compute ssh controller${i} --command "chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl"

    gcloud compute ssh controller${i} --command "sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/bin/"

    gcloud compute ssh controller${i} --command "wget https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/master/token.csv"

    gcloud compute ssh controller${i} --command "cat token.csv"

    gcloud compute ssh controller${i} --command "sudo mv token.csv /var/lib/kubernetes/"

    gcloud compute ssh controller${i} --command "wget https://raw.githubusercontent.com/kelseyhightower/kubernetes-the-hard-way/master/authorization-policy.jsonl"

    gcloud compute ssh controller${i} --command "cat authorization-policy.jsonl"

    gcloud compute ssh controller${i} --command "sudo mv authorization-policy.jsonl /var/lib/kubernetes/"

    INTERNAL_IP=$(gcloud compute ssh controller${i} --command 'curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip')

    # kube-apiserver
    gcloud compute ssh controller${i} --command "echo '[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-apiserver \
  --admission-control=NamespaceLifecycle,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota \
  --advertise-address=${INTERNAL_IP} \
  --allow-privileged=true \
  --apiserver-count=3 \
  --authorization-mode=ABAC \
  --authorization-policy-file=/var/lib/kubernetes/authorization-policy.jsonl \
  --bind-address=0.0.0.0 \
  --enable-swagger-ui=true \
  --etcd-cafile=/var/lib/kubernetes/ca.pem \
  --insecure-bind-address=0.0.0.0 \
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \
  --etcd-servers=${ETCD_SERVERS} \
  --service-account-key-file=/var/lib/kubernetes/kubernetes-key.pem \
  --service-cluster-ip-range=10.32.0.0/24 \
  --service-node-port-range=30000-32767 \
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \
  --token-auth-file=/var/lib/kubernetes/token.csv \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target' > kube-apiserver.service"


    #gcloud compute ssh controller${i} --command 'INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip); sed -i s/INTERNAL_IP/${INTERNAL_IP}/g kube-apiserver.service'
    gcloud compute ssh controller${i} --command "sudo mv kube-apiserver.service /etc/systemd/system/"
    gcloud compute ssh controller${i} --command "sudo systemctl daemon-reload"
    gcloud compute ssh controller${i} --command "sudo systemctl enable kube-apiserver"
    gcloud compute ssh controller${i} --command "sudo systemctl start kube-apiserver"
    gcloud compute ssh controller${i} --command "sudo systemctl status kube-apiserver --no-pager"

    # kube-controller-manager
    #gcloud compute copy-files kube-controller-manager.service controller${i}:~/
    gcloud compute ssh controller${i} --command "echo '[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-controller-manager \
  --allocate-node-cidrs=true \
  --cluster-cidr=10.200.0.0/16 \
  --cluster-name=kubernetes \
  --leader-elect=true \
  --master=http://${INTERNAL_IP}:8080 \
  --root-ca-file=/var/lib/kubernetes/ca.pem \
  --service-account-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \
  --service-cluster-ip-range=10.32.0.0/24 \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target' > kube-controller-manager.service"

    #gcloud compute ssh controller${i} --command 'INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip); sed -i s/INTERNAL_IP/${INTERNAL_IP}/g kube-controller-manager.service'
    gcloud compute ssh controller${i} --command "sudo mv kube-controller-manager.service /etc/systemd/system/"
    gcloud compute ssh controller${i} --command "sudo systemctl daemon-reload"
    gcloud compute ssh controller${i} --command "sudo systemctl enable kube-controller-manager"
    gcloud compute ssh controller${i} --command "sudo systemctl start kube-controller-manager"
    gcloud compute ssh controller${i} --command "sudo systemctl status kube-controller-manager --no-pager"

    # kube-scheduler
    #gcloud compute copy-files kube-scheduler.service controller${i}:~/
    gcloud compute ssh controller${i} --command "echo '[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-scheduler \
  --leader-elect=true \
  --master=http://${INTERNAL_IP}:8080 \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target' > kube-scheduler.service"

    #gcloud compute ssh controller${i} --command 'INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip); sed -i s/INTERNAL_IP/${INTERNAL_IP}/g kube-scheduler.service'
    gcloud compute ssh controller${i} --command "sudo mv kube-scheduler.service /etc/systemd/system/"
    gcloud compute ssh controller${i} --command "sudo systemctl daemon-reload"
    gcloud compute ssh controller${i} --command "sudo systemctl enable kube-scheduler"
    gcloud compute ssh controller${i} --command "sudo systemctl start kube-scheduler"
    gcloud compute ssh controller${i} --command "sudo systemctl status kube-scheduler --no-pager"

    # Verify components
    gcloud compute ssh controller${i} --command "kubectl get componentstatuses"
done

gcloud compute http-health-checks create kube-apiserver-check \
  --description "Kubernetes API Server Health Check" \
  --port 8080 \
  --request-path /healthz

gcloud compute target-pools create kubernetes-pool \
  --http-health-check=kube-apiserver-check

for i in $(eval echo "{0..${NUM_CONTROLLERS}}"); do
    hosts="${hosts}controller${i},"
done

hosts=$(echo ${hosts} | sed 's/,$//')

gcloud compute target-pools add-instances kubernetes-pool \
  --instances ${hosts}

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes \
  --format 'value(address)')

gcloud compute forwarding-rules create kubernetes-rule \
  --address ${KUBERNETES_PUBLIC_ADDRESS} \
  --ports 6443 \
  --target-pool kubernetes-pool \
  --region us-west1
