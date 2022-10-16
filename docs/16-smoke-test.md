# Smoke Test

In this lab you will complete a series of tasks to ensure your Kubernetes cluster is functioning correctly.

## Data Encryption

[//]: # (host:master-1)

In this section you will verify the ability to [encrypt secret data at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#verifying-that-data-is-encrypted).

Create a generic secret:

```bash
kubectl create secret generic kubernetes-the-hard-way \
  --from-literal="mykey=mydata"
```

Print a hexdump of the `kubernetes-the-hard-way` secret stored in etcd:

```bash
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
```bash
kubectl delete secret kubernetes-the-hard-way
```

## Deployments

In this section you will verify the ability to create and manage [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

Create a deployment for the [nginx](https://nginx.org/en/) web server:

```bash
kubectl create deployment nginx --image=nginx:1.23.1
```

[//]: # (command:kubectl wait deployment -n default nginx --for condition=Available=True --timeout=90s)

List the pod created by the `nginx` deployment:

```bash
kubectl get pods -l app=nginx
```

> output

```
NAME                    READY   STATUS    RESTARTS   AGE
nginx-dbddb74b8-6lxg2   1/1     Running   0          10s
```

### Services

In this section you will verify the ability to access applications remotely using [port forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).

Create a service to expose deployment nginx on node ports.

```bash
kubectl expose deploy nginx --type=NodePort --port 80
```


```bash
PORT_NUMBER=$(kubectl get svc -l app=nginx -o jsonpath="{.items[0].spec.ports[0].nodePort}")
```

Test to view NGINX page

```bash
curl http://worker-1:$PORT_NUMBER
curl http://worker-2:$PORT_NUMBER
```

> output

```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
 # Output Truncated for brevity
<body>
```

### Logs

In this section you will verify the ability to [retrieve container logs](https://kubernetes.io/docs/concepts/cluster-administration/logging/).

Retrieve the full name of the `nginx` pod:

```bash
POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
```

Print the `nginx` pod logs:

```bash
kubectl logs $POD_NAME
```

> output

```
10.32.0.1 - - [20/Mar/2019:10:08:30 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.58.0" "-"
10.40.0.0 - - [20/Mar/2019:10:08:55 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.58.0" "-"
```

### Exec

In this section you will verify the ability to [execute commands in a container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/#running-individual-commands-in-a-container).

Print the nginx version by executing the `nginx -v` command in the `nginx` container:

```bash
kubectl exec -ti $POD_NAME -- nginx -v
```

> output

```
nginx version: nginx/1.23.1
```

Prev: [DNS Addon](15-dns-addon.md)</br>
Next: [End to End Tests](17-e2e-tests.md)
