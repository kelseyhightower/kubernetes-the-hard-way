# Configuring kubectl for Remote Access

In this lab you will generate a kubeconfig file for the `kubectl` command line utility based on the `admin` user credentials.

> Run the commands in this lab from the same directory used to generate the admin client certificates.

## The Admin Kubernetes Configuration File

Each kubeconfig requires a Kubernetes API Server to connect to. To support high availability the IP address assigned to the external load balancer fronting the Kubernetes API Servers will be used.

[//]: # (host:master-1)

On `master-1`

Get the kube-api server load-balancer IP.

```bash
LOADBALANCER=$(dig +short loadbalancer)
```

Generate a kubeconfig file suitable for authenticating as the `admin` user:

```bash
{

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${LOADBALANCER}:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}
```

Reference doc for kubectl config [here](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)

## Verification

Check the health of the remote Kubernetes cluster:

```
kubectl get componentstatuses
```

> output

```
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-1               Healthy   {"health":"true"}
etcd-0               Healthy   {"health":"true"}
```

List the nodes in the remote Kubernetes cluster:

```bash
kubectl get nodes
```

> output

```
NAME       STATUS      ROLES    AGE    VERSION
worker-1   NotReady    <none>   118s   v1.24.3
worker-2   NotReady    <none>   118s   v1.24.3
```

Prev: [TLS Bootstrapping Kubernetes Workers](11-tls-bootstrapping-kubernetes-workers.md)</br>
Next: [Deploy Pod Networking](13-configure-pod-networking.md)
