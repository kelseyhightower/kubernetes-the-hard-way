# Smoke Test

In this chapter, you will complete a series of tasks to ensure your Kubernetes cluster is functioning correctly.

**All procedures in this chapter should be done in `client-1` unless an target virtual machines is specified.**

## Data Encryption

In this section you will verify the ability to [encrypt secret data at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#verifying-that-data-is-encrypted).

Create a generic secret:

```
$ kubectl create secret generic kubernetes-the-hard-way \
  --from-literal="mykey=mydata"
```

Print a hexdump of the `kubernetes-the-hard-way` secret stored in etcd:

```
$ ssh -t -i ~/.ssh/id_rsa-k8s 10.240.0.11 "sudo ETCDCTL_API=3 etcdctl get \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem\
  /registry/secrets/default/kubernetes-the-hard-way | hexdump -C"
```

> output

```
00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
00000010  73 2f 64 65 66 61 75 6c  74 2f 6b 75 62 65 72 6e  |s/default/kubern|
00000020  65 74 65 73 2d 74 68 65  2d 68 61 72 64 2d 77 61  |etes-the-hard-wa|
00000030  79 0a 6b 38 73 3a 65 6e  63 3a 61 65 73 63 62 63  |y.k8s:enc:aescbc|
00000040  3a 76 31 3a 6b 65 79 31  3a dd 3f 36 6c ce 65 9d  |:v1:key1:.?6l.e.|
00000050  b3 b1 46 1a ba ae a2 1f  e4 fa 13 0c 4b 6e 2c 3c  |..F.........Kn,<|
00000060  15 fa 88 56 84 b7 aa c0  7a ca 66 f3 de db 2b a3  |...V....z.f...+.|
00000070  88 dc b1 b1 d8 2f 16 3e  6b 4a cb ac 88 5d 23 2d  |...../.>kJ...]#-|
00000080  99 62 be 72 9f a5 01 38  15 c4 43 ac 38 5f ef 88  |.b.r...8..C.8_..|
00000090  3b 88 c1 e6 b6 06 4f ae  a8 6b c8 40 70 ac 0a d3  |;.....O..k.@p...|
000000a0  3e dc 2b b6 0f 01 b6 8b  e2 21 29 4d 32 d6 67 a6  |>.+......!)M2.g.|
000000b0  4e 6d bb 61 0d 85 22 ea  f4 d6 2d 0a af 3c 71 85  |Nm.a.."...-..<q.|
000000c0  96 27 c9 ec 90 e3 56 8c  94 a7 1c 9a 0e 00 28 11  |.'....V.......(.|
000000d0  18 28 f4 33 42 d9 57 d9  e3 e9 1c 38 e3 bc 1e c3  |.(.3B.W....8....|
000000e0  d2 47 f3 20 60 be b8 57  a7 0a                    |.G. `..W..|
000000ea
```

The etcd key should be prefixed with `k8s:enc:aescbc:v1:key1`, which indicates the `aescbc` provider was used to encrypt the data with the `key1` encryption key.


## Deployments

In this section you will verify the ability to create and manage [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

Create a deployment for the [nginx](https://nginx.org/en/) web server:

```
$ kubectl run nginx --image=nginx
```

List the pod created by the `nginx` deployment:

```
$ kubectl get pods -l run=nginx
```

> output

```
NAME                    READY   STATUS    RESTARTS   AGE
nginx-dbddb74b8-6lxg2   1/1     Running   0          10s
```

### Port Forwarding

In this section you will verify the ability to access applications remotely using [port forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).

Retrieve the full name of the `nginx` pod:

```
$ POD_NAME=$(kubectl get pods -l run=nginx -o jsonpath="{.items[0].metadata.name}")
```

Forward port `8080` on your local machine to port `80` of the `nginx` pod:

```
$ kubectl port-forward $POD_NAME 8080:80
```

> output

```
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

In a new terminal make an HTTP request using the forwarding address:

```
$ curl --head http://127.0.0.1:8080
```

> output

```
HTTP/1.1 200 OK
Server: nginx/1.15.4
Date: Sun, 30 Sep 2018 19:23:10 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 25 Sep 2018 15:04:03 GMT
Connection: keep-alive
ETag: "5baa4e63-264"
Accept-Ranges: bytes
```

Switch back to the previous terminal and stop the port forwarding to the `nginx` pod:

```
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
Handling connection for 8080
^C
```


### Logs

In this section you will verify the ability to [retrieve container logs](https://kubernetes.io/docs/concepts/cluster-administration/logging/).

Print the `nginx` pod logs:

```
$ kubectl logs $POD_NAME
```

> output

```
127.0.0.1 - - [30/Sep/2018:19:23:10 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.58.0" "-"
```


### Exec

In this section you will verify the ability to [execute commands in a container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/#running-individual-commands-in-a-container).

Print the nginx version by executing the `nginx -v` command in the `nginx` container:

```
$ kubectl exec -ti $POD_NAME -- nginx -v
```

> output

```
$ nginx version: nginx/1.15.4
```


## Services

In this section you will verify the ability to expose applications using a [Service](https://kubernetes.io/docs/concepts/services-networking/service/).

Expose the `nginx` deployment using a [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport) service:

```
$ kubectl expose deployment nginx --port 80 --type NodePort
```

> The LoadBalancer service type can not be used because your cluster is not configured with [cloud provider integration](https://kubernetes.io/docs/getting-started-guides/scratch/#cloud-provider). Setting up cloud provider integration is out of scope for this tutorial.

Retrieve the node port assigned to the `nginx` service:

```
$ NODE_PORT=$(kubectl get svc nginx \
  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
```

Retrieve the IP address of the worker node:

```
$ WORKER_IP=$(kubectl get nodes $(kubectl get pods -o wide | grep nginx | awk '{ print $7 }') -o wide | tail -1 | awk '{ print $6 }')
```

Make an HTTP request using the IP address and the `nginx` node port:

```
$ curl -I http://${WORKER_IP}:${NODE_PORT}
```

> output

```
HTTP/1.1 200 OK
Server: nginx/1.15.4
Date: Sun, 30 Sep 2018 19:25:40 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 25 Sep 2018 15:04:03 GMT
Connection: keep-alive
ETag: "5baa4e63-264"
Accept-Ranges: bytes
```

## Untrusted Workloads

This section will verify the ability to run untrusted workloads using [gVisor](https://github.com/google/gvisor).

Create the `untrusted` pod:

```
$ cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: untrusted
  annotations:
    io.kubernetes.cri.untrusted-workload: "true"
spec:
  containers:
    - name: webserver
      image: gcr.io/hightowerlabs/helloworld:2.0.0
EOF
```

### Verification

In this section you will verify the `untrusted` pod is running under gVisor (runsc) by inspecting the assigned worker node.

Verify the `untrusted` pod is running:

```
$ kubectl get pods -o wide
```

```
NAME                       READY     STATUS    RESTARTS   AGE       IP           NODE
busybox-68654f944b-djjjb   1/1       Running   0          5m        10.200.0.2   worker-0
nginx-65899c769f-xkfcn     1/1       Running   0          4m        10.200.1.2   worker-1
untrusted                  1/1       Running   0          10s       10.200.0.3   worker-0
```


Get the node's IP address where the `untrusted` pod is running:

```
$ INSTANCE_NAME=$(kubectl get pod untrusted --output=jsonpath='{.spec.nodeName}')
$ INSTANCE_IP_ADDRESS=$(kubectl get nodes ${INSTANCE_NAME} -o wide | tail -1 | awk '{ print $6 }')
```

SSH into the worker node:

```
$ ssh -i ~/.ssh/id_rsa-k8s ${INSTANCE_IP_ADDRESS}
```

List the containers running under gVisor:

```
$ sudo runsc --root  /run/containerd/runsc/k8s.io list
```

```
I0930 19:27:13.255142   20832 x:0] ***************************
I0930 19:27:13.255326   20832 x:0] Args: [runsc --root /run/containerd/runsc/k8s.io list]
I0930 19:27:13.255386   20832 x:0] Git Revision: 50c283b9f56bb7200938d9e207355f05f79f0d17
I0930 19:27:13.255429   20832 x:0] PID: 20832
I0930 19:27:13.255472   20832 x:0] UID: 0, GID: 0
I0930 19:27:13.255591   20832 x:0] Configuration:
I0930 19:27:13.255654   20832 x:0]              RootDir: /run/containerd/runsc/k8s.io
I0930 19:27:13.255781   20832 x:0]              Platform: ptrace
I0930 19:27:13.255893   20832 x:0]              FileAccess: exclusive, overlay: false
I0930 19:27:13.256004   20832 x:0]              Network: sandbox, logging: false
I0930 19:27:13.256128   20832 x:0]              Strace: false, max size: 1024, syscalls: []
I0930 19:27:13.256238   20832 x:0] ***************************
ID                                                                 PID         STATUS      BUNDLE                                                                                                                   CREATED                OWNER
79e74d0cec52a1ff4bc2c9b0bb9662f73ea918959c08bca5bcf07ddb6cb0e1fd   20449       running     /run/containerd/io.containerd.runtime.v1.linux/k8s.io/79e74d0cec52a1ff4bc2c9b0bb9662f73ea918959c08bca5bcf07ddb6cb0e1fd   0001-01-01T00:00:00Z
af7470029008a4520b5db9fb5b358c65d64c9f748fae050afb6eaf014a59fea5   20510       running     /run/containerd/io.containerd.runtime.v1.linux/k8s.io/af7470029008a4520b5db9fb5b358c65d64c9f748fae050afb6eaf014a59fea5   0001-01-01T00:00:00Z
I0930 19:27:13.259733   20832 x:0] Exiting with status: 0
```

Get the ID of the `untrusted` pod:

```
$ POD_ID=$(sudo crictl -r unix:///var/run/containerd/containerd.sock \
  pods --name untrusted -q)
```

Get the ID of the `webserver` container running in the `untrusted` pod:

```
$ CONTAINER_ID=$(sudo crictl -r unix:///var/run/containerd/containerd.sock \
  ps -p ${POD_ID} -q)
```

Use the gVisor `runsc` command to display the processes running inside the `webserver` container:

```
$ sudo runsc --root /run/containerd/runsc/k8s.io ps ${CONTAINER_ID}
```

> output

```
I0930 19:31:31.419765   21217 x:0] ***************************
I0930 19:31:31.419907   21217 x:0] Args: [runsc --root /run/containerd/runsc/k8s.io ps af7470029008a4520b5db9fb5b358c65d64c9f748fae050afb6eaf014a59fea5]
I0930 19:31:31.419959   21217 x:0] Git Revision: 50c283b9f56bb7200938d9e207355f05f79f0d17
I0930 19:31:31.420000   21217 x:0] PID: 21217
I0930 19:31:31.420041   21217 x:0] UID: 0, GID: 0
I0930 19:31:31.420081   21217 x:0] Configuration:
I0930 19:31:31.420115   21217 x:0]              RootDir: /run/containerd/runsc/k8s.io
I0930 19:31:31.420188   21217 x:0]              Platform: ptrace
I0930 19:31:31.420266   21217 x:0]              FileAccess: exclusive, overlay: false
I0930 19:31:31.420424   21217 x:0]              Network: sandbox, logging: false
I0930 19:31:31.420515   21217 x:0]              Strace: false, max size: 1024, syscalls: []
I0930 19:31:31.420676   21217 x:0] ***************************
UID       PID       PPID      C         STIME     TIME      CMD
0         1         0         0         19:26     10ms      app
I0930 19:31:31.422022   21217 x:0] Exiting with status: 0
```

Next: [Cleaning Up](14-cleanup.md)
