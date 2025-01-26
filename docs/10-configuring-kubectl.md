# Configuring kubectl for Remote Access

In this lab you will generate a kubeconfig file for the `kubectl` command line utility based on the `admin` user credentials.

> Run the commands in this lab from the `jumpbox` machine.

## The Admin Kubernetes Configuration File

Each kubeconfig requires a Kubernetes API Server to connect to.

You should be able to ping `server.kubernetes.local` based on the `/etc/hosts` DNS entry from a previous lap.

```bash
curl -k --cacert ca.crt \
  https://server.kubernetes.local:6443/version
```

```text
{
  "major": "1",
  "minor": "31",
  "gitVersion": "v1.31.2",
  "gitCommit": "5864a4677267e6adeae276ad85882a8714d69d9d",
  "gitTreeState": "clean",
  "buildDate": "2024-10-22T20:28:14Z",
  "goVersion": "go1.22.8",
  "compiler": "gc",
  "platform": "linux/arm64"
}
```

Generate a kubeconfig file suitable for authenticating as the `admin` user:

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}
```
The results of running the command above should create a kubeconfig file in the default location `~/.kube/config` used by the  `kubectl` commandline tool. This also means you can run the `kubectl` command without specifying a config.


## Verification

Check the version of the remote Kubernetes cluster:

```bash
kubectl version
```

```text
Client Version: v1.31.2
Kustomize Version: v5.4.2
Server Version: v1.31.2
```

List the nodes in the remote Kubernetes cluster:

```bash
kubectl get nodes
```

```
NAME     STATUS   ROLES    AGE   VERSION
node-0   Ready    <none>   30m   v1.31.2
node-1   Ready    <none>   35m   v1.31.2
```

Next: [Provisioning Pod Network Routes](11-pod-network-routes.md)
