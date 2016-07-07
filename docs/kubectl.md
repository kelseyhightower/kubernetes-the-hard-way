# Configuring Kubectl

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

```
kubectl config set-credentials admin --token chAng3m3
```
```
kubectl config set-cluster kubernetes-the-hard-way \
  --embed-certs=true \
  --certificate-authority=ca.pem \
  --server=https://146.148.34.151:6443
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