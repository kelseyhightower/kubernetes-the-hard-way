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
00000040  3a 76 31 3a 6b 65 79 31  3a 8c 7b 16 f3 26 59 d5  |:v1:key1:.{..&Y.|
00000050  c9 65 1c f0 3a 04 e7 66  2a f6 50 93 4e d4 d7 8c  |.e..:..f*.P.N...|
00000060  ca 24 ab 68 54 5f 31 f6  5c e5 5c c6 29 1d cc da  |.$.hT_1.\.\.)...|
00000070  22 fc c9 be 23 8a 26 b4  9b 38 1d 57 65 87 2a ac  |"...#.&..8.We.*.|
00000080  70 11 ea 06 93 b7 de ba  12 83 42 94 9d 27 8f ee  |p.........B..'..|
00000090  95 05 b0 77 31 ab 66 3d  d9 e2 38 85 f9 a5 59 3a  |...w1.f=..8...Y:|
000000a0  90 c1 46 ae b4 9d 13 05  82 58 71 4e 5b cb ac e2  |..F......XqN[...|
000000b0  3b 6e d7 10 ab 7c fc fe  dd f0 e6 0a 7b 24 2e 68  |;n...|......{$.h|
000000c0  5e 78 98 5f 33 40 f8 d2  10 30 1f de 17 3f 06 a1  |^x._3@...0...?..|
000000d0  81 bd 1f 2e be e9 35 26  2c be 39 16 cf ac c2 6d  |......5&,.9....m|
000000e0  32 56 05 7d 80 39 5d c0  a4 43 46 75 96 0c 87 49  |2V.}.9]..CFu...I|
000000f0  3c 17 1a 1c 8e 52 b1 e8  42 6b a5 e8 b2 b3 27 bc  |<....R..Bk....'.|
00000100  80 a6 53 2a 9f 57 d2 de  a3 f8 7f 84 2c 01 c9 d9  |..S*.W......,...|
00000110  4f e0 3f e7 a7 1e 46 b7  47 dc f0 53 d2 d2 e1 99  |O.?...F.G..S....|
00000120  0b b7 b3 49 d0 3c a5 e8  26 ce 2c 51 42 2c 0f 48  |...I.<..&.,QB,.H|
00000130  b1 9a 1a dd 24 d1 06 d8  34 bf 09 2e 20 cc 3d 3d  |....$...4... .==|
00000140  e2 5a e5 e4 44 b7 ae 57  49 0a                    |.Z..D..WI.|
0000014a
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
Server: nginx/1.19.1
Date: Sat, 18 Jul 2020 07:14:00 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 07 Jul 2020 15:52:25 GMT
Connection: keep-alive
ETag: "5f049a39-264"
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
127.0.0.1 - - [18/Jul/2020:07:14:00 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.64.0" "-"
```

### Exec

In this section you will verify the ability to [execute commands in a container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/#running-individual-commands-in-a-container).

Print the nginx version by executing the `nginx -v` command in the `nginx` container:

```
kubectl exec -ti $POD_NAME -- nginx -v
```

> output

```
nginx version: nginx/1.19.1
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
Server: nginx/1.19.1
Date: Sat, 18 Jul 2020 07:16:41 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 07 Jul 2020 15:52:25 GMT
Connection: keep-alive
ETag: "5f049a39-264"
Accept-Ranges: bytes
```

Next: [Cleaning Up](14-cleanup.md)
