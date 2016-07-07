# Bootstrapping a H/A etcd cluster

In this lab you will bootstrap a 3 node etcd cluster. The following virtual machines will be used:

````
NAME         ZONE           MACHINE_TYPE   INTERNAL_IP  STATUS
etcd0        us-central1-f  n1-standard-1  10.240.0.10  RUNNING
etcd1        us-central1-f  n1-standard-1  10.240.0.11  RUNNING
etcd2        us-central1-f  n1-standard-1  10.240.0.12  RUNNING
````

## Why

All Kubernetes components are stateless which greatly simplifies managing a Kubernetes cluster. All state is stored
in etcd, which is a database and must be treated special. etcd is being run on a dedicated set of machines for the 
following reasons:

* The etcd lifecycle is not tied to Kubernetes. We should be able to upgrade etcd independently of Kubernetes.
* Scaling out etcd is different than scaling out the Kubernetes Control Plane.
* Prevent other applications from taking up resources (CPU, Memory, I/O) required by etcd.

## Provision the etcd Cluster

### etcd0


```
gcloud compute ssh etcd0
```

Move the TLS certificates in place:

```
sudo mkdir -p /etc/etcd/
```

```
sudo mv ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
```

Download and install the etcd binaries:

```
wget https://github.com/coreos/etcd/releases/download/v3.0.1/etcd-v3.0.1-linux-amd64.tar.gz
```

```
tar -xvf etcd-v3.0.1-linux-amd64.tar.gz
```

```
sudo cp etcd-v3.0.1-linux-amd64/etcdctl /usr/bin/
```

```
sudo cp etcd-v3.0.1-linux-amd64/etcd /usr/bin/
```

```
sudo mkdir -p /var/lib/etcd
```

Create the etcd systemd unit file:

```
sudo sh -c 'echo "[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/bin/etcd --name etcd0 \
  --cert-file=/etc/etcd/kubernetes.pem \
  --key-file=/etc/etcd/kubernetes-key.pem \
  --peer-cert-file=/etc/etcd/kubernetes.pem \
  --peer-key-file=/etc/etcd/kubernetes-key.pem \
  --trusted-ca-file=/etc/etcd/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ca.pem \
  --initial-advertise-peer-urls https://10.240.0.10:2380 \
  --listen-peer-urls https://10.240.0.10:2380 \
  --listen-client-urls https://10.240.0.10:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://10.240.0.10:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster etcd0=https://10.240.0.10:2380,etcd1=https://10.240.0.11:2380,etcd2=https://10.240.0.12:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/etcd.service'
```

Start etcd:

```
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
```

### Verification

```
sudo systemctl status etcd
```

```
etcdctl --ca-file=/etc/etcd/ca.pem cluster-health
```

```
cluster may be unhealthy: failed to list members
Error:  client: etcd cluster is unavailable or misconfigured
error #0: client: endpoint http://127.0.0.1:2379 exceeded header timeout
error #1: dial tcp 127.0.0.1:4001: getsockopt: connection refused
```

### etcd1

```
gcloud compute ssh etcd1
```

Move the TLS certificates in place:

```
sudo mkdir -p /etc/etcd/
```

```
sudo mv ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
```

Download and install the etcd binaries:

```
wget https://github.com/coreos/etcd/releases/download/v3.0.1/etcd-v3.0.1-linux-amd64.tar.gz
```

```
tar -xvf etcd-v3.0.1-linux-amd64.tar.gz
```

```
sudo cp etcd-v3.0.1-linux-amd64/etcdctl /usr/bin/
```

```
sudo cp etcd-v3.0.1-linux-amd64/etcd /usr/bin/
```

```
sudo mkdir /var/lib/etcd
```

Create the etcd systemd unit file:

```
sudo sh -c 'echo "[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/bin/etcd --name etcd1 \
  --cert-file=/etc/etcd/kubernetes.pem \
  --key-file=/etc/etcd/kubernetes-key.pem \
  --peer-cert-file=/etc/etcd/kubernetes.pem \
  --peer-key-file=/etc/etcd/kubernetes-key.pem \
  --trusted-ca-file=/etc/etcd/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ca.pem \
  --initial-advertise-peer-urls https://10.240.0.11:2380 \
  --listen-peer-urls https://10.240.0.11:2380 \
  --listen-client-urls https://10.240.0.11:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://10.240.0.11:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster etcd0=https://10.240.0.10:2380,etcd1=https://10.240.0.11:2380,etcd2=https://10.240.0.12:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/etcd.service'
```

Start etcd:

```
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
```

#### Verification

```
sudo systemctl status etcd
```

```
etcdctl --ca-file=/etc/etcd/ca.pem cluster-health
```

```
member 3a57933972cb5131 is unreachable: no available published client urls
member f98dc20bce6225a0 is healthy: got healthy result from https://10.240.0.10:2379
member ffed16798470cab5 is healthy: got healthy result from https://10.240.0.11:2379
cluster is healthy
```

### etcd2

```
gcloud compute ssh etcd2
```

Move the TLS certificates in place:

```
sudo mkdir -p /etc/etcd/
```

```
sudo mv ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
```

Download and install the etcd binaries:

```
wget https://github.com/coreos/etcd/releases/download/v3.0.1/etcd-v3.0.1-linux-amd64.tar.gz
```

```
tar -xvf etcd-v3.0.1-linux-amd64.tar.gz
```

```
sudo cp etcd-v3.0.1-linux-amd64/etcdctl /usr/bin/
```

```
sudo cp etcd-v3.0.1-linux-amd64/etcd /usr/bin/
```

```
sudo mkdir /var/lib/etcd
```

Create the etcd systemd unit file:

```
sudo sh -c 'echo "[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/bin/etcd --name etcd2 \
  --cert-file=/etc/etcd/kubernetes.pem \
  --key-file=/etc/etcd/kubernetes-key.pem \
  --peer-cert-file=/etc/etcd/kubernetes.pem \
  --peer-key-file=/etc/etcd/kubernetes-key.pem \
  --trusted-ca-file=/etc/etcd/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ca.pem \
  --initial-advertise-peer-urls https://10.240.0.12:2380 \
  --listen-peer-urls https://10.240.0.12:2380 \
  --listen-client-urls https://10.240.0.12:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://10.240.0.12:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster etcd0=https://10.240.0.10:2380,etcd1=https://10.240.0.11:2380,etcd2=https://10.240.0.12:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/etcd.service'
```

Start etcd:

```
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
```

#### Verification

```
sudo systemctl status etcd
```

```
etcdctl --ca-file=/etc/etcd/ca.pem cluster-health
```

```
member 3a57933972cb5131 is healthy: got healthy result from https://10.240.0.12:2379
member f98dc20bce6225a0 is healthy: got healthy result from https://10.240.0.10:2379
member ffed16798470cab5 is healthy: got healthy result from https://10.240.0.11:2379
cluster is healthy
```