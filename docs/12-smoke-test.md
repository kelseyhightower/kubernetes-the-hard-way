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
00000040  3a 76 31 3a 6b 65 79 31  3a 5e 47 79 cf 90 88 5c  |:v1:key1:^Gy...\|
00000050  29 69 62 5c ad 76 07 ce  6e 9a 60 8c 7c 5b c9 8d  |)ib\.v..n.`.|[..|
00000060  8c 29 5f dc b1 71 0f 3b  b4 db d0 92 47 9e ea 64  |.)_..q.;....G..d|
00000070  78 12 03 f8 b1 21 9c f9  21 19 0b d0 03 9c ca 09  |x....!..!.......|
00000080  94 54 50 2f 0e d2 99 bd  38 fa d1 88 c0 0a 93 84  |.TP/....8.......|
00000090  f0 5b c3 ce ca 8c b9 23  4a 49 52 37 20 30 55 71  |.[.....#JIR7 0Uq|
000000a0  4d 9b 58 dd 95 83 34 7c  03 fa 66 f5 e7 24 26 99  |M.X...4|..f..$&.|
000000b0  ba f5 f3 6c 5f f7 19 5f  0e 60 8d 68 9e d3 f0 ca  |...l_.._.`.h....|
000000c0  4e cc 11 2e 45 ae 9e 41  3d f1 4b 2e 89 e5 05 81  |N...E..A=.K.....|
000000d0  8e 2e 40 78 72 d5 f9 63  9c e8 cc 65 a8 34 9a 41  |..@xr..c...e.4.A|
000000e0  f4 5b f6 9a ba b2 c2 8c  7b b5 d6 04 2a ad 79 c1  |.[......{...*.y.|
000000f0  71 9c e8 34 17 90 07 70  f4 18 a9 fd 80 3d 18 30  |q..4...p.....=.0|
00000100  1d 07 cb 35 e9 fd 44 ba  cb 28 15 1e 51 3b 29 75  |...5..D..(..Q;)u|
00000110  b9 ff 16 df d1 7b 91 b9  75 4d f8 c4 26 2e 0c f9  |.....{..uM..&...|
00000120  84 02 5e 52 a3 f5 da bd  d5 22 0e 9c 1a 87 47 89  |..^R....."....G.|
00000130  20 11 ac ce d0 c6 98 2a  96 e9 33 c5 26 b3 ec 55  | ......*..3.&..U|
00000140  f6 30 d5 5c 73 29 ca c8  8d af ab 4b fc 73 fc 11  |.0.\s).....K.s..|
00000150  c0 71 eb 20 3c 95 f9 74  61 0a                    |.q. <..ta.|
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
Server: nginx/1.27.4
Date: Sun, 06 Apr 2025 17:17:12 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Wed, 05 Feb 2025 11:06:32 GMT
Connection: keep-alive
ETag: "67a34638-267"
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
127.0.0.1 - - [06/Apr/2025:17:17:12 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.88.1" "-"
```

### Exec

In this section you will verify the ability to [execute commands in a container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/#running-individual-commands-in-a-container).

Print the nginx version by executing the `nginx -v` command in the `nginx` container:

```bash
kubectl exec -ti $POD_NAME -- nginx -v
```

```text
nginx version: nginx/1.27.4
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
Server: nginx/1.27.4
Date: Sun, 06 Apr 2025 17:18:36 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Wed, 05 Feb 2025 11:06:32 GMT
Connection: keep-alive
ETag: "67a34638-267"
Accept-Ranges: bytes
```

Next: [Cleaning Up](13-cleanup.md)
