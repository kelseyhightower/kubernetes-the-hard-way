# Bootstrapping the Kubernetes Worker Nodes

In this lab you will bootstrap 2 Kubernetes worker nodes. We already installed `containerd` and its dependencies on these nodes in the previous lab.

We will now install the kubernetes components
- [kubelet](https://kubernetes.io/docs/admin/kubelet)
- [kube-proxy](https://kubernetes.io/docs/concepts/cluster-administration/proxies).

## Prerequisites

The Certificates and Configuration are created on `controlplane01` node and then copied over to workers using `scp`.
Once this is done, the commands are to be run on first worker instance: `node01`. Login to first worker instance using SSH Terminal.

### Provisioning Kubelet Client Certificates

Kubernetes uses a [special-purpose authorization mode](https://kubernetes.io/docs/admin/authorization/node/) called Node Authorizer, that specifically authorizes API requests made by [Kubelets](https://kubernetes.io/docs/concepts/overview/components/#kubelet). In order to be authorized by the Node Authorizer, Kubelets must use a credential that identifies them as being in the `system:nodes` group, with a username of `system:node:<nodeName>`. In this section you will create a certificate for each Kubernetes worker node that meets the Node Authorizer requirements.

Generate a certificate and private key for one worker node:

On `controlplane01`:

[//]: # (host:controlplane01)

```bash
NODE01=$(dig +short node01)
```

```bash
cat > openssl-node01.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = node01
IP.1 = ${NODE01}
EOF

openssl genrsa -out node01.key 2048
openssl req -new -key node01.key -subj "/CN=system:node:node01/O=system:nodes" -out node01.csr -config openssl-node01.cnf
openssl x509 -req -in node01.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out node01.crt -extensions v3_req -extfile openssl-node01.cnf -days 1000
```

Results:

```
node01.key
node01.crt
```

### The kubelet Kubernetes Configuration File

When generating kubeconfig files for Kubelets the client certificate matching the Kubelet's node name must be used. This will ensure Kubelets are properly authorized by the Kubernetes [Node Authorizer](https://kubernetes.io/docs/admin/authorization/node/).

Get the kube-api server load-balancer IP.

```bash
LOADBALANCER=$(dig +short loadbalancer)
```

Generate a kubeconfig file for the first worker node.

On `controlplane01`:
```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=/var/lib/kubernetes/pki/ca.crt \
    --server=https://${LOADBALANCER}:6443 \
    --kubeconfig=node01.kubeconfig

  kubectl config set-credentials system:node:node01 \
    --client-certificate=/var/lib/kubernetes/pki/node01.crt \
    --client-key=/var/lib/kubernetes/pki/node01.key \
    --kubeconfig=node01.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:node01 \
    --kubeconfig=node01.kubeconfig

  kubectl config use-context default --kubeconfig=node01.kubeconfig
}
```

Results:

```
node01.kubeconfig
```

### Copy certificates, private keys and kubeconfig files to the worker node:
On `controlplane01`:

```bash
scp ca.crt node01.crt node01.key node01.kubeconfig node01:~/
```


### Download and Install Worker Binaries

All the following commands from here until the [verification](#verification) step must be run on `node01`

[//]: # (host:node01)


```bash
KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

wget -q --show-progress --https-only --timestamping \
  https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kube-proxy \
  https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${ARCH}/kubelet 
```

Reference: https://kubernetes.io/releases/download/#binaries

Create the installation directories:

```bash
sudo mkdir -p \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes/pki \
  /var/run/kubernetes
```

Install the worker binaries:

```bash
{
  chmod +x kube-proxy kubelet
  sudo mv kube-proxy kubelet /usr/local/bin/
}
```

### Configure the Kubelet

On `node01`:

Copy keys and config to correct directories and secure

```bash
{
  sudo mv ${HOSTNAME}.key ${HOSTNAME}.crt /var/lib/kubernetes/pki/
  sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubelet.kubeconfig
  sudo mv ca.crt /var/lib/kubernetes/pki/
  sudo mv kube-proxy.crt kube-proxy.key /var/lib/kubernetes/pki/
  sudo chown root:root /var/lib/kubernetes/pki/*
  sudo chmod 600 /var/lib/kubernetes/pki/*
  sudo chown root:root /var/lib/kubelet/*
  sudo chmod 600 /var/lib/kubelet/*
}
```

CIDR ranges used *within* the cluster

```bash
POD_CIDR=10.244.0.0/16
SERVICE_CIDR=10.96.0.0/16
```

Compute cluster DNS addess, which is conventionally .10 in the service CIDR range

```bash
CLUSTER_DNS=$(echo $SERVICE_CIDR | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s.10", $1, $2, $3) }')
```

Create the `kubelet-config.yaml` configuration file:

Reference: https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/

```bash
cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: /var/lib/kubernetes/pki/ca.crt
authorization:
  mode: Webhook
containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
clusterDomain: cluster.local
clusterDNS:
  - ${CLUSTER_DNS}
cgroupDriver: systemd
resolvConf: /run/systemd/resolve/resolv.conf
runtimeRequestTimeout: "15m"
tlsCertFile: /var/lib/kubernetes/pki/${HOSTNAME}.crt
tlsPrivateKeyFile: /var/lib/kubernetes/pki/${HOSTNAME}.key
registerNode: true
EOF
```

> The `resolvConf` configuration is used to avoid loops when using CoreDNS for service discovery on systems running `systemd-resolved`.

Create the `kubelet.service` systemd unit file:

```bash
cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --kubeconfig=/var/lib/kubelet/kubelet.kubeconfig \\
  --node-ip=${PRIMARY_IP} \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubernetes Proxy

On `node01`:

```bash
sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/
```

Create the `kube-proxy-config.yaml` configuration file:

Reference: https://kubernetes.io/docs/reference/config-api/kube-proxy-config.v1alpha1/

```bash
cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: /var/lib/kube-proxy/kube-proxy.kubeconfig
mode: iptables
clusterCIDR: ${POD_CIDR}
EOF
```

Create the `kube-proxy.service` systemd unit file:

```bash
cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

## Optional - Check Certificates and kubeconfigs

At `node01` node, run the following, selecting option 4

[//]: # (command:./cert_verify.sh 4)

```
./cert_verify.sh
```


### Start the Worker Services

On `node01`:

```bash
{
  sudo systemctl daemon-reload
  sudo systemctl enable kubelet kube-proxy
  sudo systemctl start kubelet kube-proxy
}
```

> Remember to run the above commands on worker node: `node01`

## Verification

[//]: # (host:controlplane01)

Now return to the `controlplane01` node.

List the registered Kubernetes nodes from the controlplane node:

```bash
kubectl get nodes --kubeconfig admin.kubeconfig
```

Output will be similar to

```
NAME       STATUS     ROLES    AGE   VERSION
node01     NotReady   <none>   93s   v1.28.4
```

The node is not ready as we have not yet installed pod networking. This comes later.

Next: [TLS Bootstrapping Kubernetes Workers](./11-tls-bootstrapping-kubernetes-workers.md)<br>
Prev: [Installing CRI on the Kubernetes Worker Nodes](./09-install-cri-workers.md)
