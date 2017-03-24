# Setting up Authentication

```
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes \
  --format 'value(address)')
```

## Authentication

* kubelet (client)
* Kubernetes API Server (server)

The other components, mainly the `scheduler` and `controller manager`, access the Kubernetes API server locally over the insecure API port which does not require authentication. The insecure port is only enabled for local access.

Generate a token:

BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')

Generate a token file:

```
cat > token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
```

Copy the `token.csv` file to each controller node:

```
KUBERNETES_CONTROLLERS=(controller0 controller1 controller2)
```
```
for host in ${KUBERNETES_CONTROLLERS[*]}; do
  gcloud compute copy-files token.csv ${host}:~/
done
```

## Client Authentication Configs

### bootstrap kubeconfig

Generate a bootstrap kubeconfig file:

```
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=bootstrap.kubeconfig
```

```
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig
```

```
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig
```

```
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig
```

### kube-proxy kubeconfig

```
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  --kubeconfig=kube-proxy.kubeconfig
```

```
kubectl config set-credentials kube-proxy \
  --client-certificate=kube-proxy.pem \
  --client-key=kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
```

```
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
```

```
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```

### Distribute client authentication configs

Copy the bootstrap kubeconfig file to each worker node:

```
KUBERNETES_WORKER_NODES=(worker0 worker1 worker2)
```

```
for host in ${KUBERNETES_WORKER_NODES[*]}; do
  gcloud compute copy-files bootstrap.kubeconfig kube-proxy.kubeconfig ${host}:~/
done
```
