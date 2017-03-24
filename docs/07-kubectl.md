# Configuring the Kubernetes Client - Remote Access

Run the following commands from the machine which will be your Kubernetes Client

## Download and Install kubectl

### OS X

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.6.0-beta.4/bin/darwin/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin
```

### Linux

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.6.0-beta.4/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin
```

## Configure Kubectl

In this section you will configure the kubectl client to point to the [Kubernetes API Server Frontend Load Balancer](04-kubernetes-controller.md#setup-kubernetes-api-server-frontend-load-balancer).

### GCE

```
KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes \
  --format 'value(address)')
```

### AWS

```
KUBERNETES_PUBLIC_ADDRESS=$(aws elb describe-load-balancers \
  --load-balancer-name kubernetes | \
  jq -r '.LoadBalancerDescriptions[].DNSName')
```
---

Also be sure to locate the CA certificate [created earlier](02-certificate-authority.md). Since we are using self-signed TLS certs we need to trust the CA certificate so we can verify the remote API Servers.

### Build up the kubeconfig entry

The following commands will build up the default kubeconfig file used by kubectl.

```
kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443
```

```
kubectl config set-credentials admin \
  --client-certificate=admin.pem \
  --client-key=admin-key.pem
```

```
kubectl config set-context default \
  --cluster=kubernetes-the-hard-way \
  --user=admin
```

```
kubectl config use-context default
```

At this point you should be able to connect securly to the remote API server:

```
kubectl get componentstatuses
```
```
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok                   
scheduler            Healthy   ok                   
etcd-2               Healthy   {"health": "true"}   
etcd-0               Healthy   {"health": "true"}   
etcd-1               Healthy   {"health": "true"}  
```


```
kubectl get nodes
```
```
NAME      STATUS    AGE       VERSION
worker0   Ready     7m        v1.6.0-beta.4
worker1   Ready     5m        v1.6.0-beta.4
worker2   Ready     2m        v1.6.0-beta.4
```
