# Bootstrapping an H/A Kubernetes Control Plane

In this lab you will bootstrap a 3 node Kubernetes controller cluster. The following virtual machines will be used:

* controller0
* controller1
* controller2

In this lab you will also create a frontend load balancer with a public IP address for remote access to the API servers and H/A.

## Why

The Kubernetes components that make up the control plane include the following components:

* API Server
* Scheduler
* Controller Manager

Each component is being run on the same machine for the following reasons:

* The Scheduler and Controller Manager are tightly coupled with the API Server
* Only one Scheduler and Controller Manager can be active at a given time, but it's ok to run multiple at the same time. Each component will elect a leader via the API Server.
* Running multiple copies of each component is required for H/A
* Running each component next to the API Server eases configuration.

## Provision the Kubernetes Controller Cluster

Run the following commands on `controller0`, `controller1`, `controller2`:

Copy the bootstrap token into place:

```
sudo mkdir -p /var/lib/kubernetes/
```

```
sudo mv token.csv /var/lib/kubernetes/
```

### TLS Certificates

The TLS certificates created in the [Setting up a CA and TLS Cert Generation](02-certificate-authority.md) lab will be used to secure communication between the Kubernetes API server and Kubernetes clients such as `kubectl` and the `kubelet` agent. The TLS certificates will also be used to authenticate the Kubernetes API server to etcd via TLS client auth.

Copy the TLS certificates to the Kubernetes configuration directory:

```
sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem /var/lib/kubernetes/
```

### Download and install the Kubernetes controller binaries

Download the official Kubernetes release binaries:

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.6.0-rc.1/bin/linux/amd64/kube-apiserver
```

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.6.0-rc.1/bin/linux/amd64/kube-controller-manager
```

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.6.0-rc.1/bin/linux/amd64/kube-scheduler
```

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.6.0-rc.1/bin/linux/amd64/kubectl
```

Install the Kubernetes binaries:

```
chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
```

```
sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/bin/
```

### Kubernetes API Server


#### Create the systemd unit file 

Capture the internal IP address:

#### GCE

```
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
```

#### AWS

```
INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
```

---

Create the systemd unit file:

```
cat > kube-apiserver.service <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-apiserver \\
  --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path="/var/lib/audit.log" \\
  --authorization-mode=RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\
  --event-ttl=1h \\
  --experimental-bootstrap-token-auth \\
  --insecure-bind-address=0.0.0.0 \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=rbac.authorization.k8s.io/v1alpha1 \\
  --service-account-key-file=/var/lib/kubernetes/ca-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --token-auth-file=/var/lib/kubernetes/token.csv \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Start the `kube-apiserver` service:

```
sudo mv kube-apiserver.service /etc/systemd/system/
```

```
sudo systemctl daemon-reload
```

```
sudo systemctl enable kube-apiserver
```

```
sudo systemctl start kube-apiserver
```

```
sudo systemctl status kube-apiserver --no-pager
```

### Kubernetes Controller Manager

```
cat > kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --allocate-node-cidrs=true \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file="/var/lib/kubernetes/ca.pem" \\
  --cluster-signing-key-file="/var/lib/kubernetes/ca-key.pem" \\
  --leader-elect=true \\
  --master=http://${INTERNAL_IP}:8080 \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/ca-key.pem \\
  --service-cluster-ip-range=10.32.0.0/16 \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Start the `kube-controller-manager` service:

```
sudo mv kube-controller-manager.service /etc/systemd/system/
```

```
sudo systemctl daemon-reload
```

```
sudo systemctl enable kube-controller-manager
```

```
sudo systemctl start kube-controller-manager
```

```
sudo systemctl status kube-controller-manager --no-pager
```

### Kubernetes Scheduler

```
cat > kube-scheduler.service <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-scheduler \\
  --leader-elect=true \\
  --master=http://${INTERNAL_IP}:8080 \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Start the `kube-scheduler` service:

```
sudo mv kube-scheduler.service /etc/systemd/system/
```

```
sudo systemctl daemon-reload
```

```
sudo systemctl enable kube-scheduler
```

```
sudo systemctl start kube-scheduler
```

```
sudo systemctl status kube-scheduler --no-pager
```

### Verification

```
kubectl get componentstatuses
```

```
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok                   
scheduler            Healthy   ok                   
etcd-0               Healthy   {"health": "true"}   
etcd-1               Healthy   {"health": "true"}   
etcd-2               Healthy   {"health": "true"}  
```

> Remember to run these steps on `controller0`, `controller1`, and `controller2`

## Setup Kubernetes API Server Frontend Load Balancer

The virtual machines created in this tutorial will not have permission to complete this section. Run the following commands from the same place used to create the virtual machines for this tutorial. 

### GCE

```
gcloud compute http-health-checks create kube-apiserver-health-check \
  --description "Kubernetes API Server Health Check" \
  --port 8080 \
  --request-path /healthz
```

```
gcloud compute target-pools create kubernetes-target-pool \
  --http-health-check=kube-apiserver-health-check
```

```
gcloud compute target-pools add-instances kubernetes-target-pool \
  --instances controller0,controller1,controller2
```

```
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region us-central1 \
  --format 'value(address)')
```

```
gcloud compute forwarding-rules create kubernetes-forwarding-rule \
  --address ${KUBERNETES_PUBLIC_ADDRESS} \
  --ports 6443 \
  --target-pool kubernetes-target-pool \
  --region us-central1
```

### AWS

```
aws elb register-instances-with-load-balancer \
  --load-balancer-name kubernetes \
  --instances ${CONTROLLER_0_INSTANCE_ID} ${CONTROLLER_1_INSTANCE_ID} ${CONTROLLER_2_INSTANCE_ID}
```
