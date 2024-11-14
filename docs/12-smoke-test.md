# Smoke Test

In this lab you will complete a series of tasks to ensure your Kubernetes cluster is functioning correctly.

## Data Encryption

In this section you will verify the ability to [encrypt secret data at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#verifying-that-data-is-encrypted).

Create a generic secret:

```bash
kubectl create secret generic kubernetes-the-hard-way \
  --from-literal="mykey=mydata"
```

Print a hexdump of the `kubernetes-the-hard-way` secret stored in etcd:

```bash
ssh root@server \
    'etcdctl get /registry/secrets/default/kubernetes-the-hard-way | hexdump -C'
```

```text
00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
00000010  73 2f 64 65 66 61 75 6c  74 2f 6b 75 62 65 72 6e  |s/default/kubern|
00000020  65 74 65 73 2d 74 68 65  2d 68 61 72 64 2d 77 61  |etes-the-hard-wa|
00000030  79 0a 6b 38 73 3a 65 6e  63 3a 61 65 73 63 62 63  |y.k8s:enc:aescbc|
00000040  3a 76 31 3a 6b 65 79 31  3a 9b 79 a5 b9 49 a2 77  |:v1:key1:.y..I.w|
00000050  c0 6a c9 12 7c b4 c7 c4  64 41 37 97 4a 83 a9 c1  |.j..|...dA7.J...|
00000060  4f 14 ae 73 ab b8 38 26  11 14 0a 40 b8 f3 0e 0a  |O..s..8&...@....|
00000070  f5 a7 a2 2c b6 35 b1 83  22 15 aa d0 dd 25 11 3e  |...,.5.."....%.>|
00000080  c4 e9 69 1c 10 7a 9d f7  dc 22 28 89 2c 83 dd 0b  |..i..z..."(.,...|
00000090  a4 5f 3a 93 0f ff 1f f8  bc 97 43 0e e5 05 5d f9  |._:.......C...].|
000000a0  ef 88 02 80 49 81 f1 58  b0 48 39 19 14 e1 b1 34  |....I..X.H9....4|
000000b0  f6 b0 9b 0a 9c 53 27 2b  23 b9 e6 52 b4 96 81 70  |.....S'+#..R...p|
000000c0  a7 b6 7b 4f 44 d4 9c 07  51 a3 1b 22 96 4c 24 6c  |..{OD...Q..".L$l|
000000d0  44 6c db 53 f5 31 e6 3f  15 7b 4c 23 06 c1 37 73  |Dl.S.1.?.{L#..7s|
000000e0  e1 97 8e 4e 1a 2e 2c 1a  da 85 c3 ff 42 92 d0 f1  |...N..,.....B...|
000000f0  87 b8 39 89 e8 46 2e b3  56 68 41 b8 1e 29 3d ba  |..9..F..VhA..)=.|
00000100  dd d8 27 4c 7f d5 fe 97  3c a3 92 e9 3d ae 47 ee  |..'L....<...=.G.|
00000110  24 6a 0b 7c ac b8 28 e6  25 a6 ce 04 80 ee c2 eb  |$j.|..(.%.......|
00000120  4c 86 fa 70 66 13 63 59  03 c2 70 57 8b fb a1 d6  |L..pf.cY..pW....|
00000130  f2 58 08 84 43 f3 70 7f  ad d8 30 63 3e ef ff b6  |.X..C.p...0c>...|
00000140  b2 06 c3 45 c5 d8 89 d3  47 4a 72 ca 20 9b cf b5  |...E....GJr. ...|
00000150  4b 3d 6d b4 58 ae 42 4b  7f 0a                    |K=m.X.BK..|
0000015a
```

The etcd key should be prefixed with `k8s:enc:aescbc:v1:key1`, which indicates the `aescbc` provider was used to encrypt the data with the `key1` encryption key.

## Deployments

In this section you will verify the ability to create and manage [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

Create a deployment for the [nginx](https://nginx.org/en/) web server:

```bash
kubectl create deployment nginx \
  --image=nginx:latest
```

List the pod created by the `nginx` deployment:

```bash
kubectl get pods -l app=nginx
```

```bash
NAME                     READY   STATUS    RESTARTS   AGE
nginx-56fcf95486-c8dnx   1/1     Running   0          8s
```

### Port Forwarding

In this section you will verify the ability to access applications remotely using [port forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).

Retrieve the full name of the `nginx` pod:

```bash
POD_NAME=$(kubectl get pods -l app=nginx \
  -o jsonpath="{.items[0].metadata.name}")
```

Forward port `8080` on your local machine to port `80` of the `nginx` pod:

```bash
kubectl port-forward $POD_NAME 8080:80
```

```text
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

In a new terminal make an HTTP request using the forwarding address:

```bash
curl --head http://127.0.0.1:8080
```

```text
HTTP/1.1 200 OK
Server: nginx/1.27.2
Date: Thu, 14 Nov 2024 00:16:32 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Wed, 02 Oct 2024 15:13:19 GMT
Connection: keep-alive
ETag: "66fd630f-267"
Accept-Ranges: bytes
```

Switch back to the previous terminal and stop the port forwarding to the `nginx` pod:

```text
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
Handling connection for 8080
^C
```

### Logs

In this section you will verify the ability to [retrieve container logs](https://kubernetes.io/docs/concepts/cluster-administration/logging/).

Print the `nginx` pod logs:

```bash
kubectl logs $POD_NAME
```

```text
...
127.0.0.1 - - [14/Nov/2024:00:16:32 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.88.1" "-"
```

### Exec

In this section you will verify the ability to [execute commands in a container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/#running-individual-commands-in-a-container).

Print the nginx version by executing the `nginx -v` command in the `nginx` container:

```bash
kubectl exec -ti $POD_NAME -- nginx -v
```

```text
nginx version: nginx/1.27.2
```

## Services

In this section you will verify the ability to expose applications using a [Service](https://kubernetes.io/docs/concepts/services-networking/service/).

Expose the `nginx` deployment using a [NodePort](https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport) service:

```bash
kubectl expose deployment nginx \
  --port 80 --type NodePort
```

> The LoadBalancer service type can not be used because your cluster is not configured with [cloud provider integration](https://kubernetes.io/docs/getting-started-guides/scratch/#cloud-provider). Setting up cloud provider integration is out of scope for this tutorial.

Retrieve the node port assigned to the `nginx` service:

```bash
NODE_PORT=$(kubectl get svc nginx \
  --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
```



Make an HTTP request using the IP address and the `nginx` node port:

```bash
curl -I http://node-0:${NODE_PORT}
```

```text
HTTP/1.1 200 OK
Server: nginx/1.25.3
Date: Sun, 29 Oct 2023 05:11:15 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 24 Oct 2023 13:46:47 GMT
Connection: keep-alive
ETag: "6537cac7-267"
Accept-Ranges: bytes
```

Next: [Cleaning Up](13-cleanup.md)
