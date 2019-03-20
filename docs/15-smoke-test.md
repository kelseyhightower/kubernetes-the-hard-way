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
sudo ETCDCTL_API=3 etcdctl get \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.crt \
  --cert=/etc/etcd/etcd-server.crt \
  --key=/etc/etcd/etcd-server.key\
  /registry/secrets/default/kubernetes-the-hard-way | hexdump -C
```

> output

```
00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
00000010  73 2f 64 65 66 61 75 6c  74 2f 6b 75 62 65 72 6e  |s/default/kubern|
00000020  65 74 65 73 2d 74 68 65  2d 68 61 72 64 2d 77 61  |etes-the-hard-wa|
00000030  79 0a 6b 38 73 3a 65 6e  63 3a 61 65 73 63 62 63  |y.k8s:enc:aescbc|
00000040  3a 76 31 3a 6b 65 79 31  3a 78 cd 3c 33 3a 60 d7  |:v1:key1:x.<3:`.|
00000050  4c 1e 4c f1 97 ce 75 6f  3d a7 f1 4b 59 e8 f9 2a  |L.L...uo=..KY..*|
00000060  17 77 20 14 ab 73 85 63  12 12 a4 8d 3c 6e 04 4c  |.w ..s.c....<n.L|
00000070  e0 84 6f 10 7b 3a 13 10  d0 cd df 81 d0 08 be fa  |..o.{:..........|
00000080  ea 74 ca 53 b3 b2 90 95  e1 ba bc 3f 88 76 db 8e  |.t.S.......?.v..|
00000090  e1 1e 17 ea 0d b0 3b e3  e3 df eb 2e 57 76 1d d0  |......;.....Wv..|
000000a0  25 ca ee 5b f2 27 c7 f2  8e 58 93 e9 28 45 8f 3a  |%..[.'...X..(E.:|
000000b0  e7 97 bf 74 86 72 fd e7  f1 bb fc f7 2d 10 4d c3  |...t.r......-.M.|
000000c0  70 1d 08 75 c3 7c 14 55  18 9d 68 73 ec e3 41 3a  |p..u.|.U..hs..A:|
000000d0  dc 41 8a 4b 9e 33 d9 3d  c0 04 60 10 cf ad a4 88  |.A.K.3.=..`.....|
000000e0  7b e7 93 3f 7a e8 1b 22  bf 0a                    |{..?z.."..|
000000ea
```

The etcd key should be prefixed with `k8s:enc:aescbc:v1:key1`, which indicates the `aescbc` provider was used to encrypt the data with the `key1` encryption key.

Cleanup:
`kubectl delete secret kubernetes-the-hard-way`

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
nginx version: nginx/1.15.4
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
NAME                       READY     STATUS    RESTARTS   AGE       IP           NODE
busybox-68654f944b-djjjb   1/1       Running   0          5m        10.200.0.2   worker-0
nginx-65899c769f-xkfcn     1/1       Running   0          4m        10.200.1.2   worker-1
untrusted                  1/1       Running   0          10s       10.200.0.3   worker-0
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
