# Bootstrapping Kubernetes Workers

In this lab you will bootstrap 3 Kubernetes worker nodes. The following virtual machines will be used:

* worker0
* worker1
* worker2

## Why

Kubernetes worker nodes are responsible for running your containers. All Kubernetes clusters need one or more worker nodes. We are running the worker nodes on dedicated machines for the following reasons:

* Ease of deployment and configuration
* Avoid mixing arbitrary workloads with critical cluster components. We are building machine with just enough resources so we don't have to worry about wasting resources.

Some people would like to run workers and cluster services anywhere in the cluster. This is totally possible, and you'll have to decide what's best for your environment.

## Prerequisites

Each worker node will provision a unique TLS client certificate as defined in the [kubelet TLS bootstrapping guide](https://kubernetes.io/docs/admin/kubelet-tls-bootstrapping/). The `kubelet-bootstrap` user must be granted permission to request a client TLS certificate. 

```
gcloud compute ssh controller0
```

Enable TLS bootstrapping by binding the `kubelet-bootstrap` user to the `system:node-bootstrapper` cluster role:

```
kubectl create clusterrolebinding kubelet-bootstrap \
  --clusterrole=system:node-bootstrapper \
  --user=kubelet-bootstrap
```

## Provision the Kubernetes Worker Nodes

Run the following commands on `worker0`, `worker1`, `worker2`:

```
sudo mkdir -p /var/lib/{kubelet,kube-proxy,kubernetes}
```

```
sudo mkdir -p /var/run/kubernetes
```

```
sudo mv bootstrap.kubeconfig /var/lib/kubelet
```

```
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy
```

Move the TLS certificates in place

```
sudo mv ca.pem /var/lib/kubernetes/
```

### Install Docker

```
wget https://get.docker.com/builds/Linux/x86_64/docker-1.12.6.tgz
```

```
tar -xvf docker-1.12.6.tgz
```

```
sudo cp docker/docker* /usr/bin/
```

Create the Docker systemd unit file:

```
cat > docker.service <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io

[Service]
ExecStart=/usr/bin/docker daemon \\
  --iptables=false \\
  --ip-masq=false \\
  --host=unix:///var/run/docker.sock \\
  --log-level=error \\
  --storage-driver=overlay
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

Start the docker service:

```
sudo mv docker.service /etc/systemd/system/docker.service
```

```
sudo systemctl daemon-reload
```

```
sudo systemctl enable docker
```

```
sudo systemctl start docker
```

```
sudo docker version
```

### Install the kubelet

The Kubelet can now use [CNI - the Container Network Interface](https://github.com/containernetworking/cni) to manage machine level networking requirements.

Download and install CNI plugins

```
sudo mkdir -p /opt/cni
```

```
wget https://storage.googleapis.com/kubernetes-release/network-plugins/cni-amd64-0799f5732f2a11b329d9e3d51b9c8f2e3759f2ff.tar.gz
```

```
sudo tar -xvf cni-amd64-0799f5732f2a11b329d9e3d51b9c8f2e3759f2ff.tar.gz -C /opt/cni
```

Download and install the Kubernetes worker binaries:

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.6.0-rc.1/bin/linux/amd64/kubectl
```

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.6.0-rc.1/bin/linux/amd64/kube-proxy
```

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.6.0-rc.1/bin/linux/amd64/kubelet
```

```
chmod +x kubectl kube-proxy kubelet
```

```
sudo mv kubectl kube-proxy kubelet /usr/bin/
```

Create the kubelet systemd unit file:

```
API_SERVERS=$(sudo cat /var/lib/kubelet/bootstrap.kubeconfig | \
  grep server | cut -d ':' -f2,3,4 | tr -d '[:space:]')
```

```
cat > kubelet.service <<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/kubelet \\
  --api-servers=${API_SERVERS} \\
  --allow-privileged=true \\
  --cluster-dns=10.32.0.10 \\
  --cluster-domain=cluster.local \\
  --container-runtime=docker \\
  --experimental-bootstrap-kubeconfig=/var/lib/kubelet/bootstrap.kubeconfig \\
  --network-plugin=kubenet \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --serialize-image-pulls=false \\
  --register-node=true \\
  --tls-cert-file=/var/lib/kubelet/kubelet-client.crt \\
  --tls-private-key-file=/var/lib/kubelet/kubelet-client.key \\
  --cert-dir=/var/lib/kubelet \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

```
sudo mv kubelet.service /etc/systemd/system/kubelet.service
```

```
sudo systemctl daemon-reload
```

```
sudo systemctl enable kubelet
```

```
sudo systemctl start kubelet
```

```
sudo systemctl status kubelet --no-pager
```

#### kube-proxy

```
cat > kube-proxy.service <<EOF
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/bin/kube-proxy \\
  --cluster-cidr=10.200.0.0/16 \\
  --masquerade-all=true \\
  --kubeconfig=/var/lib/kube-proxy/kube-proxy.kubeconfig \\
  --proxy-mode=iptables \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

```
sudo mv kube-proxy.service /etc/systemd/system/kube-proxy.service
```

```
sudo systemctl daemon-reload
```

```
sudo systemctl enable kube-proxy
```

```
sudo systemctl start kube-proxy
```

```
sudo systemctl status kube-proxy --no-pager
```

> Remember to run these steps on `worker0`, `worker1`, and `worker2`

## Approve the TLS certificate requests

Each worker node will submit a certificate signing request which must be approved before the node is allowed to join the cluster.

Log into one of the controller nodes:

```
gcloud compute ssh controller0
```

List the pending certificate requests:

```
kubectl get csr
```

```
NAME        AGE       REQUESTOR           CONDITION
csr-XXXXX   1m        kubelet-bootstrap   Pending
```

> Use the kubectl describe csr command to view the details of a specific signing request.

Approve each certificate signing request using the `kubectl certificate approve` command:

```
kubectl certificate approve csr-XXXXX
```

```
certificatesigningrequest "csr-XXXXX" approved
```

Once all certificate signing requests have been approved all nodes should be registered with the cluster:

```
kubectl get nodes
```

```
NAME      STATUS    AGE       VERSION
worker0   Ready     7m        v1.6.0-rc.1
worker1   Ready     5m        v1.6.0-rc.1
worker2   Ready     2m        v1.6.0-rc.1
```
