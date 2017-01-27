#!/usr/bin/env bash
set -x

DOCKER_VERSION=1.12.5

if [[ -z ${NUM_CONTROLLERS} || -z ${NUM_WORKERS} || -z ${KUBERNETES_VERSION} ]]; then
    echo "Must set NUM_CONTROLLERS, NUM_WORKERS and KUBERNETES_VERSION (e.g. 'vX.Y.Z') environment variables"
    exit 1
fi

(( NUM_CONTROLLERS-- ))
(( NUM_WORKERS-- ))

for i in $(eval echo "{0..${NUM_CONTROLLERS}}"); do
    API_SERVERS="${API_SERVERS}https://10.240.0.1${i}:6443,"
done

API_SERVERS=$(echo ${API_SERVERS} | sed 's/,$//')

for i in $(eval echo "{0..${NUM_WORKERS}}"); do
    gcloud compute ssh worker${i} --command "sudo mkdir -p /var/lib/kubernetes"

    gcloud compute ssh worker${i} --command "sudo cp ca.pem kubernetes-key.pem kubernetes.pem /var/lib/kubernetes/"

    # docker
    gcloud compute ssh worker${i} --command "wget https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz"
    gcloud compute ssh worker${i} --command "tar -xvf docker-${DOCKER_VERSION}.tgz"
    gcloud compute ssh worker${i} --command "sudo cp docker/docker* /usr/bin/"
    gcloud compute ssh worker${i} --command "sudo sh -c 'echo \"[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io

[Service]
ExecStart=/usr/bin/docker daemon \
  --iptables=false \
  --ip-masq=false \
  --host=unix:///var/run/docker.sock \
  --log-level=error \
  --storage-driver=overlay
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target\" > /etc/systemd/system/docker.service'"
    gcloud compute ssh worker${i} --command "sudo systemctl daemon-reload"
    gcloud compute ssh worker${i} --command "sudo systemctl enable docker"
    gcloud compute ssh worker${i} --command "sudo systemctl start docker"
    gcloud compute ssh worker${i} --command "sudo docker version"


    # Download CNI and kubernetes components
    gcloud compute ssh worker${i} --command "sudo mkdir -p /opt/cni"
    gcloud compute ssh worker${i} --command "wget https://storage.googleapis.com/kubernetes-release/network-plugins/cni-07a8a28637e97b22eb8dfe710eeae1344f69d16e.tar.gz"
    gcloud compute ssh worker${i} --command "sudo tar -xvf cni-07a8a28637e97b22eb8dfe710eeae1344f69d16e.tar.gz -C /opt/cni"
    gcloud compute ssh worker${i} --command "wget https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl"
    gcloud compute ssh worker${i} --command "wget https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kube-proxy"
    gcloud compute ssh worker${i} --command "wget https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubelet"
    gcloud compute ssh worker${i} --command "chmod +x kubectl kube-proxy kubelet"
    gcloud compute ssh worker${i} --command "sudo mv kubectl kube-proxy kubelet /usr/bin/"

    # Setup kubelet and kube-proxy
    gcloud compute ssh worker${i} --command "sudo mkdir -p /var/lib/kubelet/"

    # kubelet
    gcloud compute ssh worker${i} --command "sudo sh -c 'echo \"apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/ca.pem
    server: https://10.240.0.10:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubelet
  name: kubelet
current-context: kubelet
users:
- name: kubelet
  user:
    token: chAng3m3\" > /var/lib/kubelet/kubeconfig'"

    gcloud compute ssh worker${i} --command "sudo sh -c 'echo \"[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/kubelet \
  --allow-privileged=true \
  --api-servers=${API_SERVERS} \
  --cloud-provider= \
  --cluster-dns=10.32.0.10 \
  --cluster-domain=cluster.local \
  --container-runtime=docker \
  --docker=unix:///var/run/docker.sock \
  --network-plugin=kubenet \
  --kubeconfig=/var/lib/kubelet/kubeconfig \
  --reconcile-cidr=true \
  --serialize-image-pulls=false \
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \
  --v=2

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target\" > /etc/systemd/system/kubelet.service'"
    gcloud compute ssh worker${i} --command "sudo systemctl daemon-reload"
    gcloud compute ssh worker${i} --command "sudo systemctl enable kubelet"
    gcloud compute ssh worker${i} --command "sudo systemctl start kubelet"
    gcloud compute ssh worker${i} --command "sudo systemctl status kubelet --no-pager"

    # kube-proxy
    gcloud compute ssh worker${i} --command "sudo sh -c 'echo \"[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-proxy \
  --master=https://10.240.0.10:6443 \
  --kubeconfig=/var/lib/kubelet/kubeconfig \
  --proxy-mode=iptables \
  --v=2

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target\" > /etc/systemd/system/kube-proxy.service'"
    gcloud compute ssh worker${i} --command "sudo systemctl daemon-reload"
    gcloud compute ssh worker${i} --command "sudo systemctl enable kube-proxy"
    gcloud compute ssh worker${i} --command "sudo systemctl start kube-proxy"
    gcloud compute ssh worker${i} --command "sudo systemctl status kube-proxy --no-pager"
done
