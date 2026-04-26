# Bootstrapping the etcd Cluster

Kubernetes components are stateless and store cluster state in [etcd](https://github.com/etcd-io/etcd). In this lab you will bootstrap a single node etcd cluster.

## What You Are Building

etcd is the database for Kubernetes cluster state. The API server will use it later to store objects such as Nodes, Pods, Services, Secrets, ConfigMaps, and RBAC rules.

In this learning cluster, etcd runs only on the `server` machine and listens on localhost:

```text
jumpbox
  |
  |  scp etcd
  |  scp etcdctl
  |  scp etcd.service
  v
server
  |
  +-- /usr/local/bin/etcd
  +-- /usr/local/bin/etcdctl
  +-- /etc/systemd/system/etcd.service
  +-- /etc/etcd/
  |     +-- ca.crt
  |     +-- kube-api-server.crt
  |     +-- kube-api-server.key
  |
  +-- /var/lib/etcd/
        persistent etcd data
```

The systemd service starts a single etcd member:

```text
systemd
  |
  v
etcd.service
  |
  v
/usr/local/bin/etcd
  |
  +-- peer listener:   http://127.0.0.1:2380
  +-- client listener: http://127.0.0.1:2379
  +-- data directory:  /var/lib/etcd
```

At this point, no Kubernetes API server is using etcd yet. This lab only proves the datastore is installed, started, and able to report its cluster membership:

```text
etcdctl member list
        |
        v
single member etcd cluster is healthy enough for the next lab
```

## Prerequisites

Copy `etcd` binaries and systemd unit files to the `server` machine:

```bash
scp \
  downloads/controller/etcd \
  downloads/client/etcdctl \
  units/etcd.service \
  root@server:~/
```

The commands in this lab must be run on the `server` machine. Login to the `server` machine using the `ssh` command. Example:

```bash
ssh root@server
```

## Bootstrapping an etcd Cluster

### Install the etcd Binaries

Extract and install the `etcd` server and the `etcdctl` command line utility:

```bash
{
  mv etcd etcdctl /usr/local/bin/
}
```

### Configure the etcd Server

```bash
{
  mkdir -p /etc/etcd /var/lib/etcd
  chmod 700 /var/lib/etcd
  cp ca.crt kube-api-server.key kube-api-server.crt \
    /etc/etcd/
}
```

Each etcd member must have a unique name within an etcd cluster. Set the etcd name to match the hostname of the current compute instance:

Create the `etcd.service` systemd unit file:

```bash
mv etcd.service /etc/systemd/system/
```

### Start the etcd Server

```bash
{
  systemctl daemon-reload
  systemctl enable etcd
  systemctl start etcd
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

Next: [Bootstrapping the Kubernetes Control Plane](08-bootstrapping-kubernetes-controllers.md)
