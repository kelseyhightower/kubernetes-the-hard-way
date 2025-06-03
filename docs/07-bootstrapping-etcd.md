# Bootstrapping the etcd Cluster

Kubernetes components are stateless and store cluster state in [etcd]. In this
lab you will bootstrap a single node etcd cluster.

## Prerequisites

Copy `etcd` binaries and systemd unit files to the `controlplane` machine:

```bash
scp \
  downloads/controller/etcd \
  downloads/client/etcdctl \
  units/etcd.service \
  vagrant@controlplane:~/
```

The commands in this lab must be run on the `controlplane` machine. Login to
the `controlplane` machine using the `ssh` command. Example:

```bash
ssh vagrant@controlplane
```

## Bootstrapping an etcd Cluster

### Install the etcd Binaries

Extract and install the `etcd` server and the `etcdctl` command line utility:

```bash
{
  sudo mv etcd etcdctl /usr/local/bin/
}
```

### Configure the etcd Server

```bash
{
  sudo mkdir -p /etc/etcd /var/lib/etcd
  sudo chmod 700 /var/lib/etcd
  sudo cp ca.crt kube-apiserver.key kube-apiserver.crt \
    /etc/etcd/
}
```

Each etcd member must have a unique name within an etcd cluster. Set the etcd
name to match the hostname of the current compute instance:

Create the `etcd.service` systemd unit file:

```bash
sudo mv etcd.service /etc/systemd/system/
```

### Start the etcd Server

```bash
{
  sudo systemctl daemon-reload
  sudo systemctl enable etcd
  sudo systemctl start etcd.service
}
```

## Verification

List the etcd cluster members:

```bash
etcdctl member list
```

```text
6702b0a34e2cfd39, started, controller, http://127.0.0.1:2380, http://127.0.0.1:2379, false
```

Next: [Bootstrapping the Kubernetes Control Plane](08-bootstrapping-kubernetes-controlplane)

---

[etcd]: https://github.com/etcd-io/etcd