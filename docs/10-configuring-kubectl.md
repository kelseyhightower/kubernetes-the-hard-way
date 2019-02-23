# Configuring kubectl for Remote Access

In this chapter, you will generate a kubeconfig file for the `kubectl` command line utility based on the `admin` user credentials.

**All procedures in this chapter should be done in `client-1`.**


## The Admin Kubernetes Configuration File

Each kubeconfig requires a Kubernetes API Server to connect to. To support high availability the IP address assigned to the load balancer fronting the Kubernetes API Servers will be used.

Generate a kubeconfig file suitable for authenticating as the `admin` user:

```
$ {
  KUBERNETES_LB_ADDRESS=10.240.0.10

  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://$KUBERNETES_LB_ADDRESS:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}
```


## Verification

Check the health of the remote Kubernetes cluster:

```
$ kubectl get componentstatuses
```

The output should look like this:

```
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-1               Healthy   {"health":"true"}
etcd-2               Healthy   {"health":"true"}
etcd-0               Healthy   {"health":"true"}
```

List the nodes in the remote Kubernetes cluster:

```
$ kubectl get nodes
```

The output should look like this:

```
NAME       STATUS   ROLES    AGE    VERSION
worker-1   Ready    <none>   117s   v1.12.0
worker-2   Ready    <none>   118s   v1.12.0
worker-3   Ready    <none>   118s   v1.12.0
```

Next: [Provisioning Pod Network Routes](11-pod-network-routes.md)
