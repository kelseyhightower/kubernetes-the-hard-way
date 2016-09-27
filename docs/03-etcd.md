# Bootstrapping a H/A etcd cluster

In this lab you will bootstrap a 3 node etcd cluster. The following virtual machines will be used:

* controller0
* controller1
* controller2

## Why

All Kubernetes components are stateless which greatly simplifies managing a Kubernetes cluster. All state is stored
in etcd, which is a database and must be treated special. etcd is being run on a dedicated set of machines for the 
following reasons:

* The etcd lifecycle is not tied to Kubernetes. We should be able to upgrade etcd independently of Kubernetes.
* Scaling out etcd is different than scaling out the Kubernetes Control Plane.
* Prevent other applications from taking up resources (CPU, Memory, I/O) required by etcd.

## Provision the etcd Cluster

Run the following commands on `controller0`, `controller1`, `controller2`:

### TLS Certificates

The TLS certificates created in the [Setting up a CA and TLS Cert Generation](02-certificate-authority.md) lab will be used to secure communication between the Kubernetes API server and the etcd cluster. The TLS certificates will also be used to limit access to the etcd cluster using TLS client authentication. Only clients with a TLS certificate signed by a trusted CA will be able to access the etcd cluster.

Copy the TLS certificates to the etcd configuration directory:

```
sudo mkdir -p /etc/etcd/
```

```
sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
```

### Download and Install the etcd binaries

Download the official etcd release binaries from `coreos/etcd` GitHub project:

```
wget https://github.com/coreos/etcd/releases/download/v3.0.10/etcd-v3.0.10-linux-amd64.tar.gz
```

Extract and install the `etcd` server binary and the `etcdctl` command line client: 

```
tar -xvf etcd-v3.0.10-linux-amd64.tar.gz
```

```
sudo mv etcd-v3.0.10-linux-amd64/etcd* /usr/bin/
```

All etcd data is stored under the etcd data directory. In a production cluster the data directory should be backed by a persistent disk. Create the etcd data directory:

```
sudo mkdir -p /var/lib/etcd
```

The etcd server will be started and managed by systemd. Create the etcd systemd unit file:

```
cat > etcd.service <<"EOF"
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
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
  --initial-cluster controller0=https://10.240.0.10:2380,controller1=https://10.240.0.11:2380,controller2=https://10.240.0.12:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Set The Internal IP Address

The internal IP address will be used by etcd to serve client requests and communicate with other etcd peers.

#### GCE

```
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
```

#### AWS

```
INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
```

---

Each etcd member must have a unique name within an etcd cluster. Set the etcd name:

```
ETCD_NAME=controller$(echo $INTERNAL_IP | cut -c 11)
```

Substitute the etcd name and internal IP address:

```
sed -i s/INTERNAL_IP/${INTERNAL_IP}/g etcd.service
```

```
sed -i s/ETCD_NAME/${ETCD_NAME}/g etcd.service
```

Once the etcd systemd unit file is ready, move it to the systemd system directory:

```
sudo mv etcd.service /etc/systemd/system/
```

Start the etcd server:

```
sudo systemctl daemon-reload
```
```
sudo systemctl enable etcd
```
```
sudo systemctl start etcd
```


### Verification

```
sudo systemctl status etcd --no-pager
```

> Remember to run these steps on `controller0`, `controller1`, and `controller2`

## Verification

Once all 3 etcd nodes have been bootstrapped verify the etcd cluster is healthy:

* On one of the controller nodes run the following command:

```
etcdctl --ca-file=/etc/etcd/ca.pem cluster-health
```

```
member 3a57933972cb5131 is healthy: got healthy result from https://10.240.0.12:2379
member f98dc20bce6225a0 is healthy: got healthy result from https://10.240.0.10:2379
member ffed16798470cab5 is healthy: got healthy result from https://10.240.0.11:2379
cluster is healthy
```
