# Configuring the Kubernetes Client - Remote Access

## Download and Install kubectl

```
wget https://github.com/kubernetes/kubernetes/releases/download/v1.3.0/kubernetes.tar.gz
```

```
tar -xvf kubernetes.tar.gz
```

### OS X

```
sudo cp kubernetes/platforms/darwin/amd64/kubectl /usr/local/bin
```

### Linux

```
sudo cp kubernetes/platforms/linux/amd64/kubectl /usr/local/bin
```

## Configure Kubectl

In this section you will configure the kubectl client to point to the [Kubernetes API Server Frontend Load Balancer](docs/kubernetes-controller.md#setup-kubernetes-api-server-frontend-load-balancer).

Recall the Public IP address we allocated for the frontend load balancer:

```
gcloud compute addresses list
```
```
NAME        REGION       ADDRESS          STATUS
kubernetes  us-central1  104.197.132.159  IN_USE
```

Recall the token we setup for the admin user:

```
# /var/run/kubernetes/token.csv on the controller nodes
chAng3m3,admin,admin
```

Also be sure to locate the CA certificate [created earlier](docs/certificate-authority.md). Since we are using self-signed TLS certs we need to trust the CA certificate so we can verify the remote API Servers.

### Build up the kubeconfig entry

The following commands will build up the default kubeconfig file used by kubectl.

```
kubectl config set-cluster kubernetes-the-hard-way \
  --embed-certs=true \
  --certificate-authority=ca.pem \
  --server=https://104.197.132.159:6443
```

```
kubectl config set-credentials admin --token chAng3m3
```

```
kubectl config set-context default-context \
  --cluster=kubernetes-the-hard-way \
  --user=admin
```

```
kubectl config use-context default-context
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
NAME      STATUS    AGE
worker0   Ready     10m
worker1   Ready     12m
worker2   Ready     14m
```