# Bootstrapping the Kubernetes Control Plane

In this lab you will bootstrap the Kubernetes control plane across three EC2 instances and configure it for high availability. You will also create an external load balancer that exposes the Kubernetes API Servers to remote clients. The following components will be installed on each node: Kubernetes API Server, Scheduler, and Controller Manager.

## Prerequisites

The commands in this lab must be run on each master instance: `master-0`, `master-1`, and `master-2`. Login to each master instance using ssh. Example:

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

## Provision the Kubernetes Control Plane

Create the Kubernetes configuration directory:

```
master-x $ sudo mkdir -p /etc/kubernetes/config
```

### Download and Install the Kubernetes Controller Binaries

Download the official Kubernetes release binaries - `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, and `kubectl`:

```
master-x $ wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/amd64/kubectl"
```

Install the Kubernetes binaries:

```
master-x $ chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl
master-x $ sudo mv kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/
```

### Configure the Kubernetes API Server

```
master-x $ sudo mkdir -p /var/lib/kubernetes/

master-x $ sudo mv ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
  service-account-key.pem service-account.pem \
  encryption-config.yaml /var/lib/kubernetes/
```

The instance internal IP address will be used to advertise the API Server to members of the cluster. Retrieve the internal IP address for the current EC2 instance.

```
master-x $ INTERNAL_IP=$(curl 169.254.169.254/latest/meta-data/local-ipv4)
```

Create the `kube-apiserver.service` systemd unit file:

```
master-x $ cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379,https://10.240.0.12:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubernetes Controller Manager

Move the `kube-controller-manager` kubeconfig into place:

```
master-x $ sudo mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
```

Create the `kube-controller-manager.service` systemd unit file:

```
master-x $ cat <<EOF | sudo tee /etc/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --cluster-cidr=10.200.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig \\
  --leader-elect=true \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/service-account-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --use-service-account-credentials=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubernetes Scheduler

Move the `kube-scheduler` kubeconfig into place:

```
master-x $ sudo mv kube-scheduler.kubeconfig /var/lib/kubernetes/
```

Create the `kube-scheduler.yaml` configuration file:

```
master-x $ cat <<EOF | sudo tee /etc/kubernetes/config/kube-scheduler.yaml
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
clientConnection:
  kubeconfig: "/var/lib/kubernetes/kube-scheduler.kubeconfig"
leaderElection:
  leaderElect: true
EOF
```

Create the `kube-scheduler.service` systemd unit file:

```
master-x $ cat <<EOF | sudo tee /etc/systemd/system/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/etc/kubernetes/config/kube-scheduler.yaml \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Start the Controller Services

```
$ sudo systemctl daemon-reload
$ sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
$ sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

> Allow up to 10 seconds for the Kubernetes API Server to fully initialize.

Verify controller services are running.

```
master-x $ for svc in kube-apiserver kube-controller-manager kube-scheduler; \
  do sudo systemctl status --no-pager $svc | grep -B 3  Active; \
  done
● kube-apiserver.service - Kubernetes API Server
   Loaded: loaded (/etc/systemd/system/kube-apiserver.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2020-01-21 11:05:50 UTC; 3h 39min ago
● kube-controller-manager.service - Kubernetes Controller Manager
   Loaded: loaded (/etc/systemd/system/kube-controller-manager.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2020-01-21 11:05:50 UTC; 3h 39min ago
● kube-scheduler.service - Kubernetes Scheduler
   Loaded: loaded (/etc/systemd/system/kube-scheduler.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2020-01-21 11:05:50 UTC; 3h 39min ago
```

### Enable HTTP Health Checks

AWS [Network Load Balancer (NLB)](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html) will be used to distribute traffic across the three API servers and allow each API server to terminate TLS connections and validate client certificates. We use HTTP NLB health checks instead of HTTPS endpoint exposed by the API server. For health check purpose, the nginx webserver can be used to proxy HTTP health checks. In this section nginx will be installed and configured to accept HTTP health checks on port `80` and proxy the connections to the API server on `https://127.0.0.1:6443/healthz`.

> The `/healthz` API server endpoint does not require authentication by default.

Install a basic web server to handle HTTP health checks:

```
master-x $ sudo apt-get update
master-x $ sudo apt-get install -y nginx
```

Configure nginx config file to proxy HTTP health check.

```
master-x $ cat > kubernetes.default.svc.cluster.local <<EOF
server {
  listen      80;
  server_name kubernetes.default.svc.cluster.local;

  location /healthz {
     proxy_pass                    https://127.0.0.1:6443/healthz;
     proxy_ssl_trusted_certificate /var/lib/kubernetes/ca.pem;
  }
}
EOF

master-x $ sudo mv kubernetes.default.svc.cluster.local \
  /etc/nginx/sites-available/kubernetes.default.svc.cluster.local

master-x $ sudo ln -s /etc/nginx/sites-available/kubernetes.default.svc.cluster.local /etc/nginx/sites-enabled/
```

Restart the nginx.

```
master-x $ sudo systemctl restart nginx
```

Then, enable the nginx as a sytemd service.

```
master-x $ sudo systemctl enable nginx
```

### Verification

```
master-x $ kubectl get componentstatuses --kubeconfig admin.kubeconfig

NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-2               Healthy   {"health": "true"}
etcd-0               Healthy   {"health": "true"}
etcd-1               Healthy   {"health": "true"}
```

Test the nginx HTTP health check proxy:

```
master-x $ curl -H "Host: kubernetes.default.svc.cluster.local" -i http://127.0.0.1/healthz

HTTP/1.1 200 OK
Server: nginx/1.14.0 (Ubuntu)
Date: Tue, 21 Jan 2020 14:56:30 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 2
Connection: keep-alive
X-Content-Type-Options: nosniff

ok
```

> Remember to run the above commands on each master node: `master-0`, `master-1`, and `master-2`.

## RBAC for Kubelet Authorization

In this section you will configure RBAC permissions to allow the Kubernetes API Server to access the Kubelet API on each worker node (`master<kube-apiserver> --> worker<kubelet>`). Access to the Kubelet API is required for retrieving metrics, logs, and executing commands in pods.

> This tutorial sets the Kubelet `--authorization-mode` flag to `Webhook`. Webhook mode uses the [SubjectAccessReview](https://kubernetes.io/docs/admin/authorization/#checking-api-access) API to determine authorization.

The commands in this section will effect the entire cluster and only need to be run once from **one of the** master nodes.

```
$ aws ec2 describe-instances --filters Name=vpc-id,Values=vpc-xxxxxxxxxxxxxxxxx \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value | [0],InstanceId,Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress,State.Name]' \
  --output text | sort | grep master
master-0        i-xxxxxxxxxxxxxxxxx     ap-northeast-1c 10.240.0.10     xx.xxx.xxx.xxx  running
...

$ ssh -i ~/.ssh/your_ssh_key ubuntu@xx.xxx.xxx.xxx
```

Create the `system:kube-apiserver-to-kubelet` [ClusterRole](https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole) with permissions to access the Kubelet API and perform most common tasks associated with managing pods.

> NOTE: you should turn off tmux multiple sync sessions when executing following command on one master node as `ClusterRole` is a cluster-wide resource.

```
master-0 $ hostname
master-0

master-0 $ cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
```

The Kubernetes API Server authenticates to the Kubelet as the `kubernetes` user using the client certificate as defined by the `--kubelet-client-certificate` flag.

Bind the `system:kube-apiserver-to-kubelet` ClusterRole to the `kubernetes` user:

```
master-0 $ cat <<EOF | kubectl apply --kubeconfig admin.kubeconfig -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
```

Verify:

```
master-0 $ kubectl get clusterrole,clusterrolebinding | grep kube-apiserver
clusterrole.rbac.authorization.k8s.io/system:kube-apiserver-to-kubelet   2m2s
clusterrolebinding.rbac.authorization.k8s.io/system:kube-apiserver       112s
```

## The Kubernetes Frontend Load Balancer

In this section you will provision an external (internet-facing) [Network Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html) in your AWS account to front the Kubernetes API Servers. The `eip-kubernetes-the-hard-way` static IP address will be attached to the resulting load balancer.

### Provision a Network Load Balancer

Create the external (internet-facing) network load balancer network resources:

Reference: [cloudformation/hard-k8s-nlb.cfn.yml](../cloudformation/hard-k8s-nlb.cfn.yml)
```yaml
Resources:
  HardK8sNLB:
    Type: AWS::ElasticLoadBalancingV2::LoadBalancer
    Properties:
      Type: network
      Scheme: internet-facing
      SubnetMappings:
        - AllocationId: !ImportValue hard-k8s-eipalloc
          SubnetId: !ImportValue hard-k8s-subnet

  HardK8sListener:
    Type: AWS::ElasticLoadBalancingV2::Listener
    Properties:
      DefaultActions:
        - TargetGroupArn: !Ref HardK8sTargetGroup
          Type: forward
      LoadBalancerArn: !Ref HardK8sNLB
      Port: 6443
      Protocol: TCP

  HardK8sTargetGroup:
    Type: AWS::ElasticLoadBalancingV2::TargetGroup
    Properties:
      VpcId: !ImportValue hard-k8s-vpc
      Protocol: TCP
      Port: 6443
      Targets:
        - Id: !ImportValue hard-k8s-master-0
        - Id: !ImportValue hard-k8s-master-1
        - Id: !ImportValue hard-k8s-master-2
      HealthCheckPort: "80" # default is "traffic-port", which means 6443.
```

Create NLB via CloudFormation.

```
$ aws cloudformation create-stack \
  --stack-name hard-k8s-nlb \
  --template-body file://cloudformation/hard-k8s-nlb.cfn.yml
```

### Verification


Retrieve the `eip-kubernetes-the-hard-way` Elastic IP address:

```
$ KUBERNETES_PUBLIC_ADDRESS=$(aws ec2 describe-addresses \
  --filters "Name=tag:Name,Values=eip-kubernetes-the-hard-way" \
  --query 'Addresses[0].PublicIp' --output text)
```

This EIP is attached to the NLB we've just created. Make a HTTP request for the Kubernetes version info:

```
$ curl --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version
{
  "major": "1",
  "minor": "15",
  "gitVersion": "v1.15.3",
  "gitCommit": "2d3c76f9091b6bec110a5e63777c332469e0cba2",
  "gitTreeState": "clean",
  "buildDate": "2019-08-19T11:05:50Z",
  "goVersion": "go1.12.9",
  "compiler": "gc",
  "platform": "linux/amd64"
} 
```

Now we've provisioned master nodes for our k8s cluster. However, we don't have any worker nodes in the cluster.

```
master-0 $ kubectl --kubeconfig admin.kubeconfig get nodes
No resources found.
```

Let's configure them next.

Next: [Bootstrapping the Kubernetes Worker Nodes](09-bootstrapping-kubernetes-workers.md)