# Bootstrapping the Kubernetes Control Plane

In this lab you will bootstrap the Kubernetes control plane across 2 compute instances and configure it for high availability. You will also create an external load balancer that exposes the Kubernetes API Servers to remote clients. The following components will be installed on each node: Kubernetes API Server, Scheduler, and Controller Manager.

Note that in a production-ready cluster it is recommended to have an odd number of master nodes as for multi-node services like etcd, leader election and quorum work better. See lecture on this ([KodeKloud](https://kodekloud.com/topic/etcd-in-ha/), [Udemy](https://www.udemy.com/course/certified-kubernetes-administrator-with-practice-tests/learn/lecture/14296192#overview)). We're only using two here to save on RAM on your workstation.

## Prerequisites

The commands in this lab up as far as the load balancer configuration must be run on each controller instance: `master-1`, and `master-2`. Login to each controller instance using SSH Terminal.

You can perform this step with [tmux](01-prerequisites.md#running-commands-in-parallel-with-tmux)

## Provision the Kubernetes Control Plane

[//]: # (host:master-1-master2)

### Download and Install the Kubernetes Controller Binaries

Download the official Kubernetes release binaries:

```bash
wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.24.3/bin/linux/amd64/kubectl"
```

Reference: https://kubernetes.io/releases/download/#binaries

Install the Kubernetes binaries:

```bash
{
  chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
  sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
}
```

### Configure the Kubernetes API Server

Place the key pairs into the kubernetes data directory and secure

```bash
{
  sudo mkdir -p /var/lib/kubernetes/pki

  # Only copy CA keys as we'll need them again for workers.
  sudo cp ca.crt ca.key /var/lib/kubernetes/pki
  for c in kube-apiserver service-account apiserver-kubelet-client etcd-server kube-scheduler kube-controller-manager
  do
    sudo mv "$c.crt" "$c.key" /var/lib/kubernetes/pki/
  done
  sudo chown root:root /var/lib/kubernetes/pki/*
  sudo chmod 600 /var/lib/kubernetes/pki/*
}
```

The instance internal IP address will be used to advertise the API Server to members of the cluster. The load balancer IP address will be used as the external endpoint to the API servers.<br>
Retrieve these internal IP addresses:

```bash
INTERNAL_IP=$(ip addr show enp0s8 | grep "inet " | awk '{print $2}' | cut -d / -f 1)
LOADBALANCER=$(dig +short loadbalancer)
```

IP addresses of the two master nodes, where the etcd servers are.

```bash
MASTER_1=$(dig +short master-1)
MASTER_2=$(dig +short master-2)
```

CIDR ranges used *within* the cluster

```bash
POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/16
```

Create the `kube-apiserver.service` systemd unit file:

```bash
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=2 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
  --enable-admission-plugins=NodeRestriction,ServiceAccount \\
  --enable-bootstrap-token-auth=true \\
  --etcd-cafile=/var/lib/kubernetes/pki/ca.crt \\
  --etcd-certfile=/var/lib/kubernetes/pki/etcd-server.crt \\
  --etcd-keyfile=/var/lib/kubernetes/pki/etcd-server.key \\
  --etcd-servers=https://${MASTER_1}:2379,https://${MASTER_2}:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/pki/ca.crt \\
  --kubelet-client-certificate=/var/lib/kubernetes/pki/apiserver-kubelet-client.crt \\
  --kubelet-client-key=/var/lib/kubernetes/pki/apiserver-kubelet-client.key \\
  --runtime-config=api/all=true \\
  --service-account-key-file=/var/lib/kubernetes/pki/service-account.crt \\
  --service-account-signing-key-file=/var/lib/kubernetes/pki/service-account.key \\
  --service-account-issuer=https://${LOADBALANCER}:6443 \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/pki/kube-apiserver.crt \\
  --tls-private-key-file=/var/lib/kubernetes/pki/kube-apiserver.key \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubernetes Controller Manager

Move the `kube-controller-manager` kubeconfig into place:

```bash
sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
```

Create the `kube-controller-manager.service` systemd unit file:

```bash
cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --allocate-node-cidrs=true \\
  --authentication-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --authorization-kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --bind-address=127.0.0.1 \\
  --client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
  --cluster-cidr=${POD_CIDR} \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/pki/ca.crt \\
  --cluster-signing-key-file=/var/lib/kubernetes/pki/ca.key \\
  --controllers=*,bootstrapsigner,tokencleaner \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --node-cidr-mask-size=24 \\
  --requestheader-client-ca-file=/var/lib/kubernetes/pki/ca.crt \\
  --root-ca-file=/var/lib/kubernetes/pki/ca.crt \\
  --service-account-private-key-file=/var/lib/kubernetes/pki/service-account.key \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubernetes Scheduler

Move the `kube-scheduler` kubeconfig into place:

```bash
sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
```

Create the `kube-scheduler.service` systemd unit file:

```bash
cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig \\
  --leader-elect=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

## Secure kubeconfigs

```bash
sudo chmod 600 /var/lib/kubernetes/*.kubeconfig
```

## Optional - Check Certificates and kubeconfigs

At `master-1` and `master-2` nodes, run the following, selecting option 3

```bash
./cert_verify.sh
```


### Start the Controller Services

```bash
{
  sudo systemctl daemon-reload
  sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
  sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
}
```

> Allow up to 10 seconds for the Kubernetes API Server to fully initialize.


### Verification

[//]: # (sleep:10)

```bash
kubectl get componentstatuses --kubeconfig admin.kubeconfig
```

It will give you a deprecation warning here, but that's ok.

> Output

```
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-0               Healthy   {"health": "true"}
etcd-1               Healthy   {"health": "true"}
```

> Remember to run the above commands on each controller node: `master-1`, and `master-2`.

## The Kubernetes Frontend Load Balancer

In this section you will provision an external load balancer to front the Kubernetes API Servers. The `kubernetes-the-hard-way` static IP address will be attached to the resulting load balancer.


### Provision a Network Load Balancer

A NLB operates at [layer 4](https://en.wikipedia.org/wiki/OSI_model#Layer_4:_Transport_layer) (TCP) meaning it passes the traffic straight through to the back end servers unfettered and does not interfere with the TLS process, leaving this to the Kube API servers.

Login to `loadbalancer` instance using SSH Terminal.

[//]: # (host:loadbalancer)


```bash
sudo apt-get update && sudo apt-get install -y haproxy
```

Read IP addresses of master nodes and this host to shell variables

```bash
MASTER_1=$(dig +short master-1)
MASTER_2=$(dig +short master-2)
LOADBALANCER=$(dig +short loadbalancer)
```

Create HAProxy configuration to listen on API server port on this host and distribute requests evently to the two master nodes.

```bash
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
frontend kubernetes
    bind ${LOADBALANCER}:6443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server master-1 ${MASTER_1}:6443 check fall 3 rise 2
    server master-2 ${MASTER_2}:6443 check fall 3 rise 2
EOF
```

```bash
sudo systemctl restart haproxy
```

### Verification

[//]: # (sleep:2)

Make a HTTP request for the Kubernetes version info:

```bash
curl  https://${LOADBALANCER}:6443/version -k
```

> output

```
{
  "major": "1",
  "minor": "24",
  "gitVersion": "v1.24.3",
  "gitCommit": "aef86a93758dc3cb2c658dd9657ab4ad4afc21cb",
  "gitTreeState": "clean",
  "buildDate": "2022-07-13T14:23:26Z",
  "goVersion": "go1.18.3",
  "compiler": "gc",
  "platform": "linux/amd64"
}
```

Prev: [Bootstrapping the etcd Cluster](07-bootstrapping-etcd.md)<br>
Next: [Installing CRI on the Kubernetes Worker Nodes](09-install-cri-workers.md)
