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
00000040  3a 76 31 3a 6b 65 79 31  3a 97 d1 2c cd 89 0d 08  |:v1:key1:..,....|
00000050  29 3c 7d 19 41 cb ea d7  3d 50 45 88 82 a3 1f 11  |)<}.A...=PE.....|
00000060  26 cb 43 2e c8 cf 73 7d  34 7e b1 7f 9f 71 d2 51  |&.C...s}4~...q.Q|
00000070  45 05 16 e9 07 d4 62 af  f8 2e 6d 4a cf c8 e8 75  |E.....b...mJ...u|
00000080  6b 75 1e b7 64 db 7d 7f  fd f3 96 62 e2 a7 ce 22  |ku..d.}....b..."|
00000090  2b 2a 82 01 c3 f5 83 ae  12 8b d5 1d 2e e6 a9 90  |+*..............|
000000a0  bd f0 23 6c 0c 55 e2 52  18 78 fe bf 6d 76 ea 98  |..#l.U.R.x..mv..|
000000b0  fc 2c 17 36 e3 40 87 15  25 13 be d6 04 88 68 5b  |.,.6.@..%.....h[|
000000c0  a4 16 81 f6 8e 3b 10 46  cb 2c ba 21 35 0c 5b 49  |.....;.F.,.!5.[I|
000000d0  e5 27 20 4c b3 8e 6b d0  91 c2 28 f1 cc fa 6a 1b  |.' L..k...(...j.|
000000e0  31 19 74 e7 a5 66 6a 99  1c 84 c7 e0 b0 fc 32 86  |1.t..fj.......2.|
000000f0  f3 29 5a a4 1c d5 a4 e3  63 26 90 95 1e 27 d0 14  |.)Z.....c&...'..|
00000100  94 f0 ac 1a cd 0d b9 4b  ae 32 02 a0 f8 b7 3f 0b  |.......K.2....?.|
00000110  6f ad 1f 4d 15 8a d6 68  95 63 cf 7d 04 9a 52 71  |o..M...h.c.}..Rq|
00000120  75 ff 87 6b c5 42 e1 72  27 b5 e9 1a fe e8 c0 3f  |u..k.B.r'......?|
00000130  d9 04 5e eb 5d 43 0d 90  ce fa 04 a8 4a b0 aa 01  |..^.]C......J...|
00000140  cf 6d 5b 80 70 5b 99 3c  d6 5c c0 dc d1 f5 52 4a  |.m[.p[.<.\....RJ|
00000150  2c 2d 28 5a 63 57 8e 4f  df 0a                    |,-(ZcW.O..|
0000015a
```

The etcd key should be prefixed with `k8s:enc:aescbc:v1:key1`, which indicates the `aescbc` provider was used to encrypt the data with the `key1` encryption key.

## Deployments

In this section you will verify the ability to create and manage [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

Create a deployment for the [nginx](https://nginx.org/en/) web server:

```
kubectl create deployment nginx --image=nginx
```

List the pod created by the `nginx` deployment:

```
kubectl get pods -l app=nginx
```

> output

```
NAME                    READY   STATUS    RESTARTS   AGE
nginx-f89759699-kpn5m   1/1     Running   0          10s
```

### Port Forwarding

In this section you will verify the ability to access applications remotely using [port forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).

Retrieve the full name of the `nginx` pod:

```
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
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
Server: nginx/1.19.10
Date: Sun, 02 May 2021 05:29:25 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 13 Apr 2021 15:13:59 GMT
Connection: keep-alive
ETag: "6075b537-264"
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
...
127.0.0.1 - - [02/May/2021:05:29:25 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.64.0" "-"
```

### Exec

In this section you will verify the ability to [execute commands in a container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/#running-individual-commands-in-a-container).

Print the nginx version by executing the `nginx -v` command in the `nginx` container:

```
kubectl exec -ti $POD_NAME -- nginx -v
```

> output

```
nginx version: nginx/1.19.10
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
Server: nginx/1.19.10
Date: Sun, 02 May 2021 05:31:52 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 13 Apr 2021 15:13:59 GMT
Connection: keep-alive
ETag: "6075b537-264"
Accept-Ranges: bytes
```

Next: [Cleaning Up](14-cleanup.md)
