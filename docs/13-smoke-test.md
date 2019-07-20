# Smoke Test

In this lab you will complete a series of tasks to ensure your Kubernetes cluster is functioning correctly.

## Data Encryption

In this section you will verify the ability to [encrypt secret data at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#verifying-that-data-is-encrypted).

Create a generic secret:

```
kubectl create secret generic kubernetes-the-hard-way \
  --from-literal="mykey=mydata"
```

Print a hexdump of the `kubernetes-the-hard-way` secret stored in etcd:

```
gcloud compute ssh controller-0 \
  --command "sudo ETCDCTL_API=3 etcdctl get \
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
00000040  3a 76 31 3a 6b 65 79 31  3a aa 70 a0 fd d1 7a 44  |:v1:key1:.p...zD|
00000050  4a f0 ac 97 10 42 9f 6a  5b 67 1a be c6 5a b4 7a  |J....B.j[g...Z.z|
00000060  dd 4a 3e 55 fa e3 7f 3e  04 05 87 c7 ea 4a 79 d5  |.J>U...>.....Jy.|
00000070  41 3c 84 15 cc db 86 76  92 fc 99 c4 fb 5c f1 9d  |A<.....v.....\..|
00000080  c4 7f e9 ec 20 a2 0a 0e  81 65 94 00 b4 7f 84 b6  |.... ....e......|
00000090  b3 8e a4 ac c9 6f dc 1e  de ee 54 41 84 4d 66 7b  |.....o....TA.Mf{|
000000a0  de d7 ee 5e 0e 24 84 58  33 69 c9 d6 b4 90 29 33  |...^.$.X3i....)3|
000000b0  78 53 bb f3 99 ac 7c 5b  f8 a5 0c 37 4e df 1f 6c  |xS....|[...7N..l|
000000c0  ca b9 8d f0 42 4c a0 be  13 a7 65 13 62 f8 13 7d  |....BL....e.b..}|
000000d0  0d 86 cf ea 55 80 ec f7  16 b1 74 35 d3 aa 4a dc  |....U.....t5..J.|
000000e0  43 ef 19 df 71 3f 2e 1e  6a 0a                    |C...q?..j.|
```

The etcd key should be prefixed with `k8s:enc:aescbc:v1:key1`, which indicates the `aescbc` provider was used to encrypt the data with the `key1` encryption key.

## Deployments

In this section you will verify the ability to create and manage [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

Create a deployment for the [nginx](https://nginx.org/en/) web server:

```
kubectl run nginx --image=nginx
```

List the pod created by the `nginx` deployment:

```
kubectl get pods -l run=nginx
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
POD_NAME=$(kubectl get pods -l run=nginx -o jsonpath="{.items[0].metadata.name}")
```

Forward port `8080` on your local machine to port `80` of the `nginx` pod:

```
kubectl port-forward $POD_NAME 8080:80
```

> output

```
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

In a new terminal make an HTTP request using the forwarding address:

```
curl --head http://127.0.0.1:8080
```

> output

```
HTTP/1.1 200 OK
Server: nginx/1.17.1
Date: Sat, 20 Jul 2019 15:03:02 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 25 Jun 2019 12:19:45 GMT
Connection: keep-alive
ETag: "5d121161-264"
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
kubectl logs $POD_NAME
```

> output

```
127.0.0.1 - - [30/Sep/2018:19:23:10 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.58.0" "-"
```

### Exec

In this section you will verify the ability to [execute commands in a container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/#running-individual-commands-in-a-container).

Print the nginx version by executing the `nginx -v` command in the `nginx` container:

```
kubectl exec -ti $POD_NAME -- nginx -v
```

> output

```
nginx version: nginx/1.17.1
```

## Services

In this section you will verify the ability to expose applications using a [Service](https://kubernetes.io/docs/concepts/services-networking/service/).

Expose the `nginx` deployment using a [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport) service:

```
kubectl expose deployment nginx --port 80 --type NodePort
```

> The LoadBalancer service type can not be used because your cluster is not configured with [cloud provider integration](https://kubernetes.io/docs/getting-started-guides/scratch/#cloud-provider). Setting up cloud provider integration is out of scope for this tutorial.

Retrieve the node port assigned to the `nginx` service:

```
NODE_PORT=$(kubectl get svc nginx \
  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
```

Create a firewall rule that allows remote access to the `nginx` node port:

```
gcloud compute firewall-rules create kubernetes-the-hard-way-allow-nginx-service \
  --allow=tcp:${NODE_PORT} \
  --network kubernetes-the-hard-way
```

Retrieve the external IP address of a worker instance:

```
EXTERNAL_IP=$(gcloud compute instances describe worker-0 \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
```

Make an HTTP request using the external IP address and the `nginx` node port:

```
curl -I http://${EXTERNAL_IP}:${NODE_PORT}
```

> output

```
HTTP/1.1 200 OK
Server: nginx/1.17.1
Date: Sat, 20 Jul 2019 15:06:31 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 25 Jun 2019 12:19:45 GMT
Connection: keep-alive
ETag: "5d121161-264"
Accept-Ranges: bytes
```

## Untrusted Workloads

This section will verify the ability to run untrusted workloads using [gVisor](https://github.com/google/gvisor).

Create the `untrusted` pod:

```
cat <<EOF | kubectl apply -f -
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
kubectl get pods -o wide
```
```
NAME                       READY   STATUS    RESTARTS   AGE     IP           NODE       NOMINATED NODE   READINESS GATES
busybox-78c88d76df-gm8sm   1/1     Running   0          16m     10.200.2.5   worker-2   <none>           <none>
nginx-7bb7cd8db5-vxhg8     1/1     Running   0          4m58s   10.200.2.6   worker-2   <none>           <none>
untrusted                  1/1     Running   0          4s      10.200.0.6   worker-0   <none>           <none>
```


Get the node name where the `untrusted` pod is running:

```
INSTANCE_NAME=$(kubectl get pod untrusted --output=jsonpath='{.spec.nodeName}')
```

SSH into the worker node:

```
gcloud compute ssh ${INSTANCE_NAME}
```

List the containers running under gVisor:

```
sudo runsc --root  /run/containerd/runsc/k8s.io list
```
```
I0720 15:08:16.434026   12656 x:0] ***************************
I0720 15:08:16.434241   12656 x:0] Args: [runsc --root /run/containerd/runsc/k8s.io list]
I0720 15:08:16.434316   12656 x:0] Git Revision: 50c283b9f56bb7200938d9e207355f05f79f0d17
I0720 15:08:16.434386   12656 x:0] PID: 12656
I0720 15:08:16.434443   12656 x:0] UID: 0, GID: 0
I0720 15:08:16.434496   12656 x:0] Configuration:
I0720 15:08:16.434539   12656 x:0]              RootDir: /run/containerd/runsc/k8s.io
I0720 15:08:16.434635   12656 x:0]              Platform: ptrace
I0720 15:08:16.434740   12656 x:0]              FileAccess: exclusive, overlay: false
I0720 15:08:16.434839   12656 x:0]              Network: sandbox, logging: false
I0720 15:08:16.434936   12656 x:0]              Strace: false, max size: 1024, syscalls: []
I0720 15:08:16.435031   12656 x:0] ***************************
ID                                                                 PID         STATUS      BUNDLE                                                                                                                   CREATED                OWNER
913a16578531d71155a32ad69b08d8243aba86162324d84ac9adca67a11901a6   12348       running     /run/containerd/io.containerd.runtime.v1.linux/k8s.io/913a16578531d71155a32ad69b08d8243aba86162324d84ac9adca67a11901a6   0001-01-01T00:00:00Z   
b7ff7c891ebdd9046879f8949dfa165b4b03f12c11d3f2baf27e4ff4a23e87f6   12408       running     /run/containerd/io.containerd.runtime.v1.linux/k8s.io/b7ff7c891ebdd9046879f8949dfa165b4b03f12c11d3f2baf27e4ff4a23e87f6   0001-01-01T00:00:00Z   
I0720 15:08:16.438491   12656 x:0] Exiting with status: 0
```

Get the ID of the `untrusted` pod:

```
POD_ID=$(sudo crictl -r unix:///var/run/containerd/containerd.sock \
  pods --name untrusted -q)
```

Get the ID of the `webserver` container running in the `untrusted` pod:

```
CONTAINER_ID=$(sudo crictl -r unix:///var/run/containerd/containerd.sock \
  ps -p ${POD_ID} -q)
```

Use the gVisor `runsc` command to display the processes running inside the `webserver` container:

```
sudo runsc --root /run/containerd/runsc/k8s.io ps ${CONTAINER_ID}
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
