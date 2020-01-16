# Smoke Test

In this lab you will complete a series of tasks to ensure your Kubernetes cluster is functioning correctly.

## Data Encryption

In this section you will verify the ability to [encrypt secret data at rest](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#verifying-that-data-is-encrypted).

Create a generic secret:

```
$ kubectl create secret generic kubernetes-the-hard-way \
  --from-literal="mykey=mydata"
```

Print a hexdump of the `kubernetes-the-hard-way` secret stored in etcd:

```
$ ssh <<master-0>>
```

```
master-0 $ sudo ETCDCTL_API=3 etcdctl get \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem\
  /registry/secrets/default/kubernetes-the-hard-way | hexdump -C

00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
00000010  73 2f 64 65 66 61 75 6c  74 2f 6b 75 62 65 72 6e  |s/default/kubern|
00000020  65 74 65 73 2d 74 68 65  2d 68 61 72 64 2d 77 61  |etes-the-hard-wa|
00000030  79 0a 6b 38 73 3a 65 6e  63 3a 61 65 73 63 62 63  |y.k8s:enc:aescbc|
00000040  3a 76 31 3a 6b 65 79 31  3a 24 a3 f7 aa 22 b1 d2  |:v1:key1:$..."..|
00000050  7b 9f 89 aa 53 a6 a0 5e  e4 5f 1f ea b2 d6 c4 de  |{...S..^._......|
00000060  c2 80 02 a9 57 e7 e6 b0  46 57 9f fa c8 dd 89 c3  |....W...FW......|
00000070  ef 15 58 71 ab ec c3 6a  9f 7e da b9 d8 94 2e 0d  |..Xq...j.~......|
00000080  85 a3 ff 94 56 62 a1 dd  f6 4b a6 47 d1 46 b6 92  |....Vb...K.G.F..|
00000090  27 9f 4d e0 5c 81 4e b4  fe 2e ca d5 5b d2 be 07  |'.M.\.N.....[...|
000000a0  1d 4e 38 b8 2b 03 37 0d  65 84 e2 8c de 87 80 c8  |.N8.+.7.e.......|
000000b0  9c f9 08 0e 4f 29 fc 5f  b3 e8 10 99 b4 00 b3 ad  |....O)._........|
000000c0  6c dd 81 28 a0 2d a6 82  41 0e 7d ba a8 a0 7d d6  |l..(.-..A.}...}.|
000000d0  15 f0 80 a5 1d 27 33 aa  a1 b5 e0 d1 e7 5b 63 22  |.....'3......[c"|
000000e0  9a 10 68 42 e6 d4 9f 0d  ab 0a                    |..hB......|
000000ea
```

The etcd key should be prefixed with `k8s:enc:aescbc:v1:key1`, which indicates the `aescbc` provider was used to encrypt the data with the `key1` encryption key.

## Deployments

In this section you will verify the ability to create and manage [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

Create a deployment for the [nginx](https://nginx.org/en/) web server:

```
$ kubectl create deployment nginx --image=nginx
```

List the pod created by the `nginx` deployment:

```
$ kubectl get pods -l app=nginx

NAME                     READY   STATUS    RESTARTS   AGE
nginx-554b9c67f9-vt5rn   1/1     Running   0          10s
```

### Port Forwarding

In this section you will verify the ability to access applications remotely using [port forwarding](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/).

Retrieve the full name of the `nginx` pod:

```
$ POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
```

Forward port `8080` on your local machine to port `80` of the `nginx` pod:

```
$ kubectl port-forward $POD_NAME 8080:80

Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

In a new terminal make an HTTP request using the forwarding address:

```
$ curl --head http://127.0.0.1:8080

HTTP/1.1 200 OK
Server: nginx/1.17.8
Date: Fri, 24 Jan 2020 19:31:41 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 21 Jan 2020 13:36:08 GMT
Connection: keep-alive
ETag: "5e26fe48-264"
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

127.0.0.1 - - [14/Sep/2019:21:10:11 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.52.1" "-"
```

### Exec

In this section you will verify the ability to [execute commands in a container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/#running-individual-commands-in-a-container).

Print the nginx version by executing the `nginx -v` command in the `nginx` container:

```
$ kubectl exec -ti $POD_NAME -- nginx -v

nginx version: nginx/1.17.8
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
$ echo $NODE_PORT
30712
```

The value of `$NODE_PORT` varies. Create a route that allows remote access to the `nginx` node port with following CloudFormation template:

Reference: [cloudformation/hard-k8s-nodeport-sg-ingress](../cloudformation/hard-k8s-nodeport-sg-ingress.cfn.yml)
```yaml
Parameters:
  ParamNodePort:
    Type: Number
    # ref: https://kubernetes.io/docs/concepts/services-networking/service/#nodeport
    MinValue: 30000
    MaxValue: 32767

Resources:
  HardK8sSmokeIngress:
    Type: AWS::EC2::SecurityGroupIngress
    Properties:
      GroupId: !ImportValue hard-k8s-sg
      CidrIp: 0.0.0.0/0
      IpProtocol: tcp
      FromPort: !Ref ParamNodePort
      ToPort: !Ref ParamNodePort
```

You should pass `$NODE_PORT` environment variable as a CloudFormation stack parameter:

```
$ aws cloudformation create-stack \
  --stack-name hard-k8s-nodeport-sg-ingress \
  --parameters ParameterKey=ParamNodePort,ParameterValue=$NODE_PORT \
  --template-body file://cloudformation/hard-k8s-nodeport-sg-ingress.cfn.yml
```

Retrieve the external IP address of a worker instance which is hosting the nginx pod:

```
$ kubectl get pods -l app=nginx -o wide
NAME                     READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
nginx-554b9c67f9-gw87z   1/1     Running   0          27m   10.200.1.3   worker-1   <none>           <none>

$ WORKER_NODE_NAME=$(kubectl get pods -l app=nginx -o=jsonpath='{.items[0].spec.nodeName}')
$ echo $WORKER_NODE_NAME
worker-1

$ EXTERNAL_IP=$(aws ec2 describe-instances \
  --filter "Name=tag:Name,Values=${WORKER_NODE_NAME}" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
$ echo $EXTERNAL_IP
54.xxx.xxx.18
```

Make an HTTP request using the external IP address and the `nginx` node port:

```
$ curl -I http://${EXTERNAL_IP}:${NODE_PORT}

HTTP/1.1 200 OK
Server: nginx/1.17.8
Date: Fri, 24 Jan 2020 20:02:27 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 21 Jan 2020 13:36:08 GMT
Connection: keep-alive
ETag: "5e26fe48-264"
Accept-Ranges: bytes
```

Congrats! Now you have built your own Kubernetets cluster the hard way.

Next: [Cleaning Up](14-cleanup.md)