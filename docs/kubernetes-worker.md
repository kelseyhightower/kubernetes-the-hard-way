# Bootstrapping Kubernetes Workers

In this lab you will bootstrap a 3 Kubernetes worker nodes. The following virtual machines will be used:

```
NAME         ZONE           MACHINE_TYPE   INTERNAL_IP  STATUS
worker0      us-central1-f  n1-standard-1  10.240.0.30  RUNNING
worker1      us-central1-f  n1-standard-1  10.240.0.31  RUNNING
worker2      us-central1-f  n1-standard-1  10.240.0.32  RUNNING
```

## Why

Kubernetes worker nodes are responsible for running your containers. All Kubernetes clusters need one or more worker nodes. We are running the worker nodes on dedicated machines for the following reasons:

* Ease of deployment and configuration
* Avoid mixing arbitrary workloads with critical cluster components. We are building machine with just enough resources so we don't have to worry about wasting resources.

Some people would like to run workers and cluster services anywhere in the cluster. This is totally possible, and you'll have to decide what's best for your environment.

## Copy TLS Certs

```
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem worker0:~/
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem worker1:~/
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem worker2:~/
```

## Provision the Kubernetes Worker Nodes

### worker0

```
gcloud compute ssh worker0
```

#### Move the TLS certificates in place

```
sudo mkdir -p /var/run/kubernetes
```

```
sudo mv ca.pem kubernetes-key.pem kubernetes.pem /var/run/kubernetes/
```

#### Docker

Kubernetes should be compatible with the Docker 1.9.x - 1.11.x:

```
wget https://get.docker.com/builds/Linux/x86_64/docker-1.11.2.tgz
```

```
tar -xvf docker-1.11.2.tgz
```

```
sudo cp docker/docker /usr/bin/
sudo cp docker/docker-containerd /usr/bin/
sudo cp docker/docker-containerd-ctr /usr/bin/
sudo cp docker/docker-containerd-shim /usr/bin/
sudo cp docker/docker-runc /usr/bin/
```

Create the Docker systemd unit file:


```
sudo sh -c 'echo "[Unit]
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
WantedBy=multi-user.target" > /etc/systemd/system/docker.service'
```

```
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl start docker
```

```
sudo docker version
```

#### kubelet

Download and install the Kubernetes worker binaries:

```
wget https://github.com/kubernetes/kubernetes/releases/download/v1.3.0/kubernetes.tar.gz
```

```
tar -xvf kubernetes.tar.gz
```

```
tar -xvf kubernetes/server/kubernetes-server-linux-amd64.tar.gz
```

```
sudo cp kubernetes/server/bin/kubectl /usr/bin/
sudo cp kubernetes/server/bin/kube-proxy /usr/bin/
sudo cp kubernetes/server/bin/kubelet /usr/bin/
```

```
mkdir -p /var/lib/kubelet/
```

```
sudo sh -c 'echo "apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /var/run/kubernetes/ca.pem
    server: https://10.240.0.20:6443
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
    token: chAng3m3" > /var/lib/kubelet/kubeconfig'
```

Create the kubelet systemd unit file:

```
sudo sh -c 'echo "[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/kubelet \
  --allow-privileged=true \
  --api-servers=https://10.240.0.20:6443,https://10.240.0.21:6443,https://10.240.0.22:6443 \
  --cloud-provider=
  --cluster-dns=10.32.0.10 \
  --cluster-domain=cluster.local \
  --configure-cbr0=true \
  --container-runtime=docker \
  --docker=unix:///var/run/docker.sock \
  --kubeconfig=/var/lib/kubelet/kubeconfig \
  --reconcile-cidr=true \
  --serialize-image-pulls=false \
  --tls-cert-file=/var/run/kubernetes/kubernetes.pem
  --tls-private-key-file=/var/run/kubernetes/kubernetes-key.pem \
  --v=2
  
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/kubelet.service'
```

```
sudo systemctl daemon-reload
sudo systemctl enable kubelet
sudo systemctl start kubelet
```

```
sudo systemctl status kubelet
```
