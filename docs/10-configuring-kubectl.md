# Configuring kubectl for Remote Access

In this lab you will generate a kubeconfig file for the `kubectl` command line utility based on the `admin` user credentials.

> Run the commands in this lab from the same directory used to generate the admin client certificates.

## The Admin Kubernetes Configuration File

Each kubeconfig requires a Kubernetes API Server to connect to. To support high availability the IP address assigned to the external load balancer fronting the Kubernetes API Servers will be used.

Generate a kubeconfig file suitable for authenticating as the `admin` user:

```
KUBERNETES_PUBLIC_ADDRESS="$(gcloud compute addresses describe kubernetes-the-hard-way \
  --format 'value(address)')"

kubectl config set-cluster kubernetes-the-hard-way \
  --certificate-authority ca.pem \
  --embed-certs \
  --server "https://${KUBERNETES_PUBLIC_ADDRESS}:6443"

kubectl config set-credentials admin \
  --client-certificate admin.pem \
  --client-key admin-key.pem

kubectl config set-context kubernetes-the-hard-way \
  --cluster kubernetes-the-hard-way \
  --user admin

kubectl config use-context kubernetes-the-hard-way
```

## Verification

Check the version of the remote Kubernetes cluster:

```
kubectl version --short
```

> output

```
Client Version: v1.27.4
Kustomize Version: v5.0.1
Server Version: v1.27.4
```

List the nodes in the remote Kubernetes cluster:

```
kubectl get nodes
```

> output

```
NAME       STATUS   ROLES    AGE     VERSION
worker-0   Ready    <none>   5m38s   v1.27.4
worker-1   Ready    <none>   5m38s   v1.27.4
worker-2   Ready    <none>   5m38s   v1.27.4
```

Next: [Provisioning Pod Network Routes](./11-pod-network-routes.md)
