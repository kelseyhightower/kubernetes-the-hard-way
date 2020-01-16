# Bootstrapping the etcd Cluster

Kubernetes components are stateless and store cluster state in [etcd](https://github.com/etcd-io/etcd). In this lab you will bootstrap a three node etcd cluster and configure it for high availability and secure remote access.

## Prerequisites

The commands in this lab must be run on each master instance: `master-0`, `master-1`, and `master-2`. Login to each master instance using ssh command. Example:

```
$ aws ec2 describe-instances --filters Name=vpc-id,Values=vpc-xxxxxxxxxxxxxxxxx \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value | [0],InstanceId,Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress,State.Name]' \
  --output text | sort | grep master
master-0        i-xxxxxxxxxxxxxxxxx     ap-northeast-1c 10.240.0.10     xx.xxx.xxx.xxx  running
...

$ ssh -i ~/.ssh/your_ssh_key ubuntu@xx.xxx.xxx.xxx
```

### Running commands in parallel with tmux

[tmux](https://github.com/tmux/tmux/wiki) can be used to run commands on multiple EC2 instances at the same time. See the [Running commands in parallel with tmux](01-prerequisites.md#running-commands-in-parallel-with-tmux) section in the Prerequisites lab.

## Bootstrapping an etcd Cluster Member

### Download and Install the etcd Binaries

Download the official etcd release binaries from the [etcd](https://github.com/etcd-io/etcd) GitHub project:

```
master-x $ wget -q --show-progress --https-only --timestamping \
  "https://github.com/etcd-io/etcd/releases/download/v3.4.0/etcd-v3.4.0-linux-amd64.tar.gz"
```

Extract and install the `etcd` server and the `etcdctl` command line utility:

```
master-x $ tar -xvf etcd-v3.4.0-linux-amd64.tar.gz
master-x $ sudo mv etcd-v3.4.0-linux-amd64/etcd* /usr/local/bin/
```

Results:

```
master-x $ ls /usr/local/bin/
etcd  etcdctl
```

### Configure the etcd Server

```
master-x $ sudo mkdir -p /etc/etcd /var/lib/etcd
master-x $ sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/
```

The instance internal IP address will be used to serve client requests and communicate with etcd cluster peers. Retrieve the internal IP address for the current EC2 instance via [instance metadata on EC2 instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instancedata-data-retrieval.html):

Example:
```
master-0 $ curl 169.254.169.254/latest/meta-data/local-ipv4
10.240.0.10
```

Set `INTERNAL_IP` environemnt variable:

```
master-x $ INTERNAL_IP=$(curl 169.254.169.254/latest/meta-data/local-ipv4)
```

Each etcd member must have a unique name within an etcd cluster. Set the etcd name to match the hostname of the current EC2 instance:

Example:

```
master-0 $ hostname -s
master-0
```

Set `ETCD_NAME` environemnt variable:

```
master-x $ ETCD_NAME=$(hostname -s)
```

Create the `etcd.service` systemd unit file:

```
master-x $ cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster master-0=https://10.240.0.10:2380,master-1=https://10.240.0.11:2380,master-2=https://10.240.0.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Start the etcd Server

```
master-x $ sudo systemctl daemon-reload
master-x $ sudo systemctl enable etcd
master-x $ sudo systemctl start etcd
```

> Remember to run the above commands on each master node: `master-0`, `master-1`, and `master-2`.

Verify etcd servers are running as systemd services.

```
master-x $ systemctl status etcd.service
● etcd.service - etcd
   Loaded: loaded (/etc/systemd/system/etcd.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2020-01-20 18:01:29 UTC; 21s ago
   ...
```

## Verification

List the etcd cluster members:

```
master-0 $ sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem

3a57933972cb5131, started, master-2, https://10.240.0.12:2380, https://10.240.0.12:2379, false
f98dc20bce6225a0, started, master-0, https://10.240.0.10:2380, https://10.240.0.10:2379, false
ffed16798470cab5, started, master-1, https://10.240.0.11:2380, https://10.240.0.11:2379, false
```

Next: [Bootstrapping the Kubernetes Control Plane](08-bootstrapping-kubernetes-controllers.md)