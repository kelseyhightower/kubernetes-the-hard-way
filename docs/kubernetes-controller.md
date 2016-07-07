# Bootstrapping an H/A Kubernetes Control Plane

In this lab you will bootstrap a 3 node Kubernetes controller cluster. The following virtual machines will be used:

```
NAME         ZONE           MACHINE_TYPE   INTERNAL_IP  STATUS
controller0  us-central1-f  n1-standard-1  10.240.0.20  RUNNING
controller1  us-central1-f  n1-standard-1  10.240.0.21  RUNNING
controller2  us-central1-f  n1-standard-1  10.240.0.22  RUNNING
```

## Why

The Kubernetes components that make up the control plane include the following components:

* Kubernetes API Server
* Kubernetes Scheduler
* Kubernetes Controller Manager

Each component is being run on the same machines for the following reasons:

* The Scheduler and Controller Manager are tightly coupled with the API Server
* Only one Scheduler and Controller Manager can be active at a given time, but it's ok to run multiple at the same time. Each component will elect a leader via the API Server.
* Running multiple copies of each component is required for H/A
* Running each component next to the API Server eases configuration.

## Copy TLS Certs

```
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem controller0:~/
```

```
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem controller1:~/
```

```
gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem controller2:~/
```

## Provision the Kubernetes Controller Cluster

### controller0

```
gcloud compute ssh controller0
```

Move the TLS certificates in place:

```
sudo mkdir -p /var/run/kubernetes
```

```
sudo mv ca.pem kubernetes-key.pem kubernetes.pem /var/run/kubernetes/
```

Download and install the Kubernetes controller binaries:

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
sudo cp kubernetes/server/bin/kube-apiserver /usr/bin/
sudo cp kubernetes/server/bin/kube-controller-manager /usr/bin/
sudo cp kubernetes/server/bin/kube-scheduler /usr/bin/
sudo cp kubernetes/server/bin/kubectl /usr/bin/
```

#### Kubernetes API Server

```
wget https://storage.googleapis.com/hightowerlabs/authorization-policy.jsonl
```

```
cat authorization-policy.jsonl
```

```
sudo mv authorization-policy.jsonl /var/run/kubernetes/
```

```
wget https://storage.googleapis.com/hightowerlabs/token.csv
```

```
cat token.csv
```

```
sudo mv token.csv /var/run/kubernetes/
```

```
sudo sh -c 'echo "[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-apiserver \
  --admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota \
  --advertise-address=10.240.0.20 \
  --allow-privileged=true \
  --apiserver-count=3 \
  --authorization-mode=ABAC \
  --authorization-policy-file=/var/run/kubernetes/authorization-policy.jsonl \
  --bind-address=0.0.0.0 \
  --enable-swagger-ui=true \
  --etcd-cafile=/var/run/kubernetes/ca.pem \
  --insecure-bind-address=127.0.0.1 \
  --kubelet-certificate-authority=/var/run/kubernetes/ca.pem \
  --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \
  --service-account-key-file=/var/run/kubernetes/kubernetes-key.pem \
  --service-cluster-ip-range=10.32.0.0/24 \
  --service-node-port-range=30000-32767 \
  --tls-cert-file=/var/run/kubernetes/kubernetes.pem \
  --tls-private-key-file=/var/run/kubernetes/kubernetes-key.pem \
  --token-auth-file=/var/run/kubernetes/token.csv
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/kube-apiserver.service'
```

```
sudo systemctl daemon-reload
sudo systemctl enable kube-apiserver
sudo systemctl start kube-apiserver
```

```
sudo systemctl status kube-apiserver
```

#### Kubernetes Controller Manager

```
sudo sh -c 'echo "[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-controller-manager \
  --cluster-cidr=10.200.0.0/16 \
  --cluster-name=kubernetes \
  --leader-elect=true \
  --master=http://127.0.0.1:8080 \
  --root-ca-file=/var/run/kubernetes/ca.pem \
  --service-account-private-key-file=/var/run/kubernetes/kubernetes-key.pem \
  --service-cluster-ip-range=10.32.0.0/24 \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/kube-controller-manager.service'
```

```
sudo systemctl daemon-reload
sudo systemctl enable kube-controller-manager
sudo systemctl start kube-controller-manager
```

```
sudo systemctl status kube-controller-manager
```

#### Kubernetes Scheduler

```
sudo sh -c 'echo "[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-scheduler \
  --leader-elect=true \
  --master=http://127.0.0.1:8080 \
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/kube-scheduler.service'
```

```
sudo systemctl daemon-reload
sudo systemctl enable kube-scheduler
sudo systemctl start kube-scheduler
```

```
sudo systemctl status kube-scheduler
```


#### Verification 

```
kubectl get componentstatuses
```
```
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok                   
scheduler            Healthy   ok                   
etcd-1               Healthy   {"health": "true"}   
etcd-0               Healthy   {"health": "true"}   
etcd-2               Healthy   {"health": "true"}  
```
