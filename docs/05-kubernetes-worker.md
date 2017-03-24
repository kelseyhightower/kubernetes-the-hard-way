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


## Provision the Kubernetes Worker Nodes

Run the following commands on `worker0`, `worker1`, `worker2`:

### Set the Kubernetes Public Address

#### GCE

```
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes \
  --format 'value(address)')
```

#### AWS

```
KUBERNETES_PUBLIC_ADDRESS=$(aws elb describe-load-balancers \
  --load-balancer-name kubernetes | \
  jq -r '.LoadBalancerDescriptions[].DNSName')
```

---

```
sudo mkdir -p /var/lib/kubelet
```

```
sudo mv bootstrap.kubeconfig /var/lib/kubelet
```

#### Move the TLS certificates in place

```
sudo mkdir -p /var/lib/kubernetes
```

```
sudo mv ca.pem /var/lib/kubernetes/
```

#### Docker

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

```
sudo mv docker.service /etc/systemd/system/docker.service
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

The Kubernetes kubelet no longer relies on docker networking for pods! The Kubelet can now use [CNI - the Container Network Interface](https://github.com/containernetworking/cni) to manage machine level networking requirements.

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
wget https://storage.googleapis.com/kubernetes-release/release/v1.6.0-beta.4/bin/linux/amd64/kubectl
```
```
wget https://storage.googleapis.com/kubernetes-release/release/v1.6.0-beta.4/bin/linux/amd64/kube-proxy
```
```
wget https://storage.googleapis.com/kubernetes-release/release/v1.6.0-beta.4/bin/linux/amd64/kubelet
```

```
chmod +x kubectl kube-proxy kubelet
```

```
sudo mv kubectl kube-proxy kubelet /usr/bin/
```

Create the kubelet systemd unit file:

```
cat > kubelet.service <<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/bin/kubelet \\
  --api-servers=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \\
  --allow-privileged=true \\
  --cloud-provider=auto-detect \\
  --cluster-dns=10.32.0.10 \\
  --cluster-domain=cluster.local \\
  --container-runtime=docker \\
  --experimental-bootstrap-kubeconfig=/var/lib/kubelet/bootstrap.kubeconfig \\
  --network-plugin=kubenet \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --serialize-image-pulls=false \\
  --register-node=true \\
  --tls-cert-file=/var/run/kubernetes/kubelet-client.crt \\
  --tls-private-key-file=/var/run/kubernetes/kubelet-client.key \\
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
sudo systemctl enable kubelet
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
  --master=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --proxy-mode=iptables \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```
sudo mv kube-proxy.service /etc/systemd/system/kube-proxy.service
```

```
sudo systemctl daemon-reload
sudo systemctl enable kube-proxy
sudo systemctl start kube-proxy
```

```
sudo systemctl status kube-proxy --no-pager
```

> Remember to run these steps on `worker0`, `worker1`, and `worker2`
