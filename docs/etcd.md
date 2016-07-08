# Bootstrapping a H/A etcd cluster

In this lab you will bootstrap a 3 node etcd cluster. The following virtual machines will be used:

```
gcloud compute instances list
```

````
NAME   ZONE           MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP      STATUS
etcd0  us-central1-f  n1-standard-1               10.240.0.10  XXX.XXX.XXX.XXX  RUNNING
etcd1  us-central1-f  n1-standard-1               10.240.0.11  XXX.XXX.XXX.XXX  RUNNING
etcd2  us-central1-f  n1-standard-1               10.240.0.12  XXX.XXX.XXX.XXX  RUNNING
````

## Why

All Kubernetes components are stateless which greatly simplifies managing a Kubernetes cluster. All state is stored
in etcd, which is a database and must be treated special. etcd is being run on a dedicated set of machines for the 
following reasons:

* The etcd lifecycle is not tied to Kubernetes. We should be able to upgrade etcd independently of Kubernetes.
* Scaling out etcd is different than scaling out the Kubernetes Control Plane.
* Prevent other applications from taking up resources (CPU, Memory, I/O) required by etcd.

## Provision the etcd Cluster

Run the following commands on `etcd0`, `etcd1`, `etcd2`:

> SSH into each machine using the `gcloud compute ssh` command

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
cat > etcd.service <<"EOF"
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/bin/etcd --name ETCD_NAME \
  --cert-file=/etc/etcd/kubernetes.pem \
  --key-file=/etc/etcd/kubernetes-key.pem \
  --peer-cert-file=/etc/etcd/kubernetes.pem \
  --peer-key-file=/etc/etcd/kubernetes-key.pem \
  --trusted-ca-file=/etc/etcd/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ca.pem \
  --initial-advertise-peer-urls https://INTERNAL_IP:2380 \
  --listen-peer-urls https://INTERNAL_IP:2380 \
  --listen-client-urls https://INTERNAL_IP:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://INTERNAL_IP:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster etcd0=https://10.240.0.10:2380,etcd1=https://10.240.0.11:2380,etcd2=https://10.240.0.12:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

```
export INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
```

```
export ETCD_NAME=$(hostname -s)
```

```
sed -i s/INTERNAL_IP/$INTERNAL_IP/g etcd.service
```

```
sed -i s/ETCD_NAME/$ETCD_NAME/g etcd.service
```

```
sudo mv etcd.service /etc/systemd/system/
```

Start etcd:

```
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
```

### Verification

```
sudo systemctl status etcd --no-pager
```

## Verification

Once all 3 etcd nodes have been bootstrapped verify the etcd cluster is healthy:

```
gcloud compute ssh etcd0
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