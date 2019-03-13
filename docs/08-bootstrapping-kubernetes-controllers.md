# Bootstrapping the Kubernetes Control Plane

In this lab you will bootstrap the Kubernetes control plane across three compute instances and configure it for high availability. You will also create an external load balancer that exposes the Kubernetes API Servers to remote clients. The following components will be installed on each node: Kubernetes API Server, Scheduler, and Controller Manager.

## Prerequisites

The commands in this lab must be run on each controller instance: `controller-0`, `controller-1`, and `controller-2`. Login to each controller instance using the `gcloud` command. Example:

```
gcloud compute ssh controller-0
```

### Running commands in parallel with tmux

[tmux](https://github.com/tmux/tmux/wiki) can be used to run commands on multiple compute instances at the same time. See the [Running commands in parallel with tmux](01-prerequisites.md#running-commands-in-parallel-with-tmux) section in the Prerequisites lab.

## Provision the Kubernetes Control Plane

Create the Kubernetes configuration directory:

```
sudo mkdir -p /etc/kubernetes/config
```

### Download and Install the Kubernetes Controller Binaries

Download the official Kubernetes release binaries:

```
wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.12.0/bin/linux/amd64/kubectl"
```

Install the Kubernetes binaries:

```
{
  chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
  sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
}
```

Running below test cases to verify:

```
{
  (ls /usr/local/bin/kube-apiserver >> /dev/null 2>&1 && echo "PASSED kube-apiserver") || echo "FAILED kube-apiserver"
  (ls /usr/local/bin/kube-controller-manager >> /dev/null 2>&1 && echo "PASSED kube-controller-manager") || echo "FAILED kube-controller-manager"
  (ls /usr/local/bin/kube-scheduler >> /dev/null 2>&1 && echo "PASSED kube-scheduler") || echo "FAILED kube-scheduler"
  (ls /usr/local/bin/kubectl >> /dev/null 2>&1 && echo "PASSED kubectl") || echo "FAILED kubectl"
}
```

### Configure the Kubernetes API Server

```
{
  sudo mkdir -p /var/lib/kubernetes/

  sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem \
    encryption-config.yaml /var/lib/kubernetes/
}
```

The instance internal IP address will be used to advertise the API Server to members of the cluster. Retrieve the internal IP address for the current compute instance:

```
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
```

Create the `kube-apiserver.service` systemd unit file:

```
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=Initializers,NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\
  --event-ttl=1h \\
  --experimental-encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Running below test cases to verify:

```
{
  $CTRLER0_IP=10.240.0.10
  $CTRLER1_IP=10.240.0.11
  $CTRLER2_IP=10.240.0.12
  (ls /var/lib/kubernetes/ca.pem >> /dev/null 2>&1 && echo "PASSED ca.pem") || echo "FAILED ca.pem"
  (ls /var/lib/kubernetes/ca-key.pem >> /dev/null 2>&1 && echo "PASSED ca-key.pem") || echo "FAILED ca-key.pem"
  (ls /var/lib/kubernetes/kubernetes.pem >> /dev/null 2>&1 && echo "PASSED kubernetes.pem") || echo "FAILED kubernetes.pem"
  (ls /var/lib/kubernetes/kubernetes-key.pem >> /dev/null 2>&1 && echo "PASSED kubernetes-key.pem") || echo "FAILED kubernetes-key.pem"
  (ls /var/lib/kubernetes/service-account.pem >> /dev/null 2>&1 && echo "PASSED service-account.pem") || echo "FAILED service-account.pem"
  (ls /var/lib/kubernetes/service-account-key.pem >> /dev/null 2>&1 && echo "PASSED service-account-key.pem") || echo "FAILED service-account-key.pem"
  (ls /var/lib/kubernetes/encryption-config.yaml >> /dev/null 2>&1 && echo "PASSED encryption-config.yaml") || echo "FAILED encryption-config.yaml"
  (ls /etc/systemd/system/kube-apiserver.service >> /dev/null 2>&1 && echo "PASSED kube-apiserver.service") || echo "FAILED kube-apiserver.service"
  (grep -o 'etcd-servers=[^"]*' /etc/systemd/system/kube-apiserver.service | grep ${CTRLER0_IP} >> /dev/null 2>&1 && echo "PASSED etcd-servers ${CTRLER0_IP}") || echo "FAILED etcd-servers ${CTRLER0_IP}"
  (grep -o 'etcd-servers=[^"]*' /etc/systemd/system/kube-apiserver.service | grep ${CTRLER1_IP} >> /dev/null 2>&1 && echo "PASSED etcd-servers ${CTRLER1_IP}") || echo "FAILED etcd-servers ${CTRLER1_IP}"
  (grep -o 'etcd-servers=[^"]*' /etc/systemd/system/kube-apiserver.service | grep ${CTRLER2_IP} >> /dev/null 2>&1 && echo "PASSED etcd-servers ${CTRLER2_IP}") || echo "FAILED etcd-servers ${CTRLER2_IP}"
}
```

### Configure the Kubernetes Controller Manager

Move the `kube-controller-manager` kubeconfig into place:

```
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
```

Create the `kube-controller-manager.service` systemd unit file:

```
cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Running below test cases to verify:

```
{
  (ls /var/lib/kubernetes/kube-controller-manager.kubeconfig >> /dev/null 2>&1 && echo "PASSED kube-controller-manager.kubeconfig") || echo "FAILED kube-controller-manager.kubeconfig"
  (ls /etc/systemd/system/kube-controller-manager.service >> /dev/null 2>&1 && echo "PASSED kube-controller-manager.service") || echo "FAILED kube-controller-manager.service"
  (ls /var/lib/kubernetes/ca.pem >> /dev/null 2>&1 && echo "PASSED ca.pem") || echo "FAILED ca.pem"
  (ls /var/lib/kubernetes/ca-key.pem >> /dev/null 2>&1 && echo "PASSED ca-key.pem.pem") || echo "FAILED ca-key.pem.pem"
  (ls /var/lib/kubernetes/service-account-key.pem >> /dev/null 2>&1 && echo "PASSED service-account-key.pem") || echo "FAILED service-account-key.pem"
  (grep -o 'ExecStart=[^"]*' /etc/systemd/system/kube-controller-manager.service | grep "/usr/local/bin/kube-controller-manager" >> /dev/null 2>&1 && echo "PASSED ExecStart") || echo "FAILED ExecStart"
  (grep -o 'cluster-signing-cert-file=[^"]*' /etc/systemd/system/kube-controller-manager.service | grep "/var/lib/kubernetes/ca.pem" >> /dev/null 2>&1 && echo "PASSED cluster-signing-cert-file") || echo "FAILED cluster-signing-cert-file"
  (grep -o 'cluster-signing-key-file=[^"]*' /etc/systemd/system/kube-controller-manager.service | grep "/var/lib/kubernetes/ca-key.pem" >> /dev/null 2>&1 && echo "PASSED cluster-signing-key-file") || echo "FAILED cluster-signing-key-file"
  (grep -o 'kubeconfig=[^"]*' /etc/systemd/system/kube-controller-manager.service | grep "/var/lib/kubernetes/kube-controller-manager.kubeconfig" >> /dev/null 2>&1 && echo "PASSED kubeconfig") || echo "FAILED kubeconfig"
  (grep -o 'root-ca-file=[^"]*' /etc/systemd/system/kube-controller-manager.service | grep "/var/lib/kubernetes/ca.pem" >> /dev/null 2>&1 && echo "PASSED root-ca-file") || echo "FAILED root-ca-file"
  (grep -o 'service-account-private-key-file=[^"]*' /etc/systemd/system/kube-controller-manager.service | grep "/var/lib/kubernetes/service-account-key.pem" >> /dev/null 2>&1 && echo "PASSED service-account-private-key-file") || echo "FAILED service-account-private-key-file"
}
```

### Configure the Kubernetes Scheduler

Move the `kube-scheduler` kubeconfig into place:

```
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
```

Create the `kube-scheduler.yaml` configuration file:

```
cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: componentconfig/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
```

Create the `kube-scheduler.service` systemd unit file:

```
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Running below test cases to verify:

```
{
  (ls /var/lib/kubernetes/kube-scheduler.kubeconfig >> /dev/null 2>&1 && echo "PASSED kube-scheduler.kubeconfig") || echo "FAILED kube-scheduler.kubeconfig"
  (ls /etc/kubernetes/config/kube-scheduler.yaml >> /dev/null 2>&1 && echo "PASSED kube-scheduler.yaml") || echo "FAILED kube-scheduler.yaml"
  (ls /etc/systemd/system/kube-scheduler.service >> /dev/null 2>&1 && echo "PASSED kube-scheduler.service") || echo "FAILED kube-scheduler.service"
  (ls /usr/local/bin/kube-scheduler >> /dev/null 2>&1 && echo "PASSED kube-scheduler") || echo "FAILED kube-scheduler"
  (grep -o 'kubeconfig:[^:]*' /etc/kubernetes/config/kube-scheduler.yaml | grep "/var/lib/kubernetes/kube-scheduler.kubeconfig" >> /dev/null 2>&1 && echo "PASSED kubeconfig") || echo "FAILED kubeconfig"
  (grep -o 'ExecStart=[^"]*' /etc/systemd/system/kube-scheduler.service | grep "/usr/local/bin/kube-scheduler" >> /dev/null 2>&1 && echo "PASSED ExecStart") || echo "FAILED ExecStart"
  (grep -o 'config=[^"]*' /etc/systemd/system/kube-scheduler.service | grep "/etc/kubernetes/config/kube-scheduler.yaml" >> /dev/null 2>&1 && echo "PASSED config") || echo "FAILED config"
}
```

### Start the Controller Services

```
{
  sudo systemctl daemon-reload
  sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
  sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
}
```

> Allow up to 10 seconds for the Kubernetes API Server to fully initialize.

### Enable HTTP Health Checks

A [Google Network Load Balancer](https://cloud.google.com/compute/docs/load-balancing/network) will be used to distribute traffic across the three API servers and allow each API server to terminate TLS connections and validate client certificates. The network load balancer only supports HTTP health checks which means the HTTPS endpoint exposed by the API server cannot be used. As a workaround the nginx webserver can be used to proxy HTTP health checks. In this section nginx will be installed and configured to accept HTTP health checks on port `80` and proxy the connections to the API server on `https://127.0.0.1:6443/healthz`.

> The `/healthz` API server endpoint does not require authentication by default.

Install a basic web server to handle HTTP health checks:

```
sudo apt-get install -y nginx
```

```
cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF
```

```
{
  sudo mv kubernetes.default.svc.cluster.local \
    /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

  sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/
}
```

```
sudo systemctl restart nginx
```

```
sudo systemctl enable nginx
```

Running below test cases to verify:

```
{
  (ls /etc/nginx/sites-available/kubernetes.default.svc.cluster.local >> /dev/null 2>&1 && echo "PASSED sites-available/kubernetes.default.svc.cluster.local") || echo "FAILED sites-available/kubernetes.default.svc.cluster.local"
  (ls /etc/nginx/sites-enabled/kubernetes.default.svc.cluster.local >> /dev/null 2>&1 && echo "PASSED sites-enabled/kubernetes.default.svc.cluster.local") || echo "FAILED sites-enabled/kubernetes.default.svc.cluster.local"
  (curl -H "Host: kubernetes.default.svc.cluster.local" -is http://127.0.0.1/healthz | grep "200 OK" >> /dev/null 2>&1 && echo "PASSED 200 OK") || echo "FAILED 200 OK"
}
```

### Verification

```
kubectl get componentstatuses --kubeconfig admin.kubeconfig
```

```
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-2               Healthy   {"health": "true"}
etcd-0               Healthy   {"health": "true"}
etcd-1               Healthy   {"health": "true"}
```

Test the nginx HTTP health check proxy:

```
curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz
```

```
HTTP/1.1 200 OK
Server: nginx/1.14.0 (Ubuntu)
Date: Sun, 30 Sep 2018 17:44:24 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 2
Connection: keep-alive

ok
```

> Remember to run the above commands on each controller node: `controller-0`, `controller-1`, and `controller-2`.

## RBAC for Kubelet Authorization

In this section you will configure RBAC permissions to allow the Kubernetes API Server to access the Kubelet API on each worker node. Access to the Kubelet API is required for retrieving metrics, logs, and executing commands in pods.

> This tutorial sets the Kubelet `--authorization-mode` flag to `Webhook`. Webhook mode uses the [SubjectAccessReview](https://kubernetes.io/docs/admin/authorization/#checking-api-access) API to determine authorization.

In this section you are interacting with your cluster as a whole, so the following 2 role creation commands only need to be run from a single controller


```
gcloud compute ssh controller-0
```

Create the `system:kube-apiserver-to-kubelet` [ClusterRole](https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole) with permissions to access the Kubelet API and perform most common tasks associated with managing pods:

```
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
```

The Kubernetes API Server authenticates to the Kubelet as the `kubernetes` user using the client certificate as defined by the `--kubelet-client-certificate` flag.

Bind the `system:kube-apiserver-to-kubelet` ClusterRole to the `kubernetes` user:

```
cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
```

## The Kubernetes Frontend Load Balancer

In this section you will provision an external load balancer to front the Kubernetes API Servers. The `kubernetes-the-hard-way` static IP address will be attached to the resulting load balancer.

> The compute instances created in this tutorial will not have permission to complete this section. Run the following commands from the same machine used to create the compute instances.


### Provision a Network Load Balancer

Create the external load balancer network resources:

```
{
  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
    --region $(gcloud config get-value compute/region) \
    --format 'value(address)')

  gcloud compute http-health-checks create kubernetes \
    --description "Kubernetes Health Check" \
    --host "kubernetes.default.svc.cluster.local" \
    --request-path "/healthz"

  gcloud compute firewall-rules create kubernetes-the-hard-way-allow-health-check \
    --network kubernetes-the-hard-way \
    --source-ranges 209.85.152.0/22,209.85.204.0/22,35.191.0.0/16 \
    --allow tcp

  gcloud compute target-pools create kubernetes-target-pool \
    --http-health-check kubernetes

  gcloud compute target-pools add-instances kubernetes-target-pool \
   --instances controller-0,controller-1,controller-2

  gcloud compute forwarding-rules create kubernetes-forwarding-rule \
    --address ${KUBERNETES_PUBLIC_ADDRESS} \
    --ports 6443 \
    --region $(gcloud config get-value compute/region) \
    --target-pool kubernetes-target-pool
}
```

### Verification

Retrieve the `kubernetes-the-hard-way` static IP address:

```
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')
```

Make a HTTP request for the Kubernetes version info:

```
curl --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version
```

> output

```
{
  "major": "1",
  "minor": "12",
  "gitVersion": "v1.12.0",
  "gitCommit": "0ed33881dc4355495f623c6f22e7dd0b7632b7c0",
  "gitTreeState": "clean",
  "buildDate": "2018-09-27T16:55:41Z",
  "goVersion": "go1.10.4",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```

Next: [Bootstrapping the Kubernetes Worker Nodes](09-bootstrapping-kubernetes-workers.md)
