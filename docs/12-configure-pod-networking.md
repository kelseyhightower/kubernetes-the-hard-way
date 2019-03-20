# Provisioning Pod Network

We chose to use CNI - [weave](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/) as our networking option.

### Install CNI plugins

Download the CNI Plugins required for weave on each of the worker nodes - `worker-1` and `worker-2`

`wget https://github.com/containernetworking/plugins/releases/download/v0.7.5/cni-plugins-amd64-v0.7.5.tgz`

Extract it to /opt/cni/bin directory

`sudo tar -xzvf cni-plugins-amd64-v0.7.5.tgz  --directory /opt/cni/bin/`

### Deploy Weave Network

Deploy weave network. Run only once on the `master` node.


`kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"`

Weave uses POD CIDR of `10.32.0.0/12` by default.

## Verification

List the registered Kubernetes nodes from the master node:

```
master-1$ kubectl get pods -n kube-system
```

> output

```
NAME                       READY   STATUS    RESTARTS   AGE
weave-net-cfzk5            2/2     Running   0          41m
```
