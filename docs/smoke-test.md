# Smoke Test

This lab walks you through a quick smoke test to make sure things are working.

## Test

```
kubectl run nginx --image=nginx --port=80 --replicas=3
```

```
deployment "nginx" created
```

```
kubectl get pods -o wide
```
```
NAME                     READY     STATUS    RESTARTS   AGE       IP           NODE
nginx-2032906785-ms8hw   1/1       Running   0          21s       10.200.2.2   worker2
nginx-2032906785-sokxz   1/1       Running   0          21s       10.200.1.2   worker1
nginx-2032906785-u8rzc   1/1       Running   0          21s       10.200.0.2   worker0
```

```
kubectl expose deployment nginx --type NodePort
```

```
service "nginx" exposed
```

> Note that --type=LoadBalancer will not work because we did not configure a cloud provider when bootstrapping this cluster.


```
kubectl describe svc nginx
```
```
Name:			nginx
Namespace:		default
Labels:			run=nginx
Selector:		run=nginx
Type:			NodePort
IP:			10.32.0.199
Port:			<unset>	80/TCP
NodePort:		<unset>	32345/TCP
Endpoints:		10.200.0.2:80,10.200.1.2:80,10.200.2.2:80
Session Affinity:	None
No events.
```

```
gcloud compute instances list
```

````
NAME         ZONE           MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP      STATUS
controller0  us-central1-f  n1-standard-1               10.240.0.20  146.148.34.151   RUNNING
controller1  us-central1-f  n1-standard-1               10.240.0.21  104.197.49.230   RUNNING
controller2  us-central1-f  n1-standard-1               10.240.0.22  130.211.123.47   RUNNING
etcd0        us-central1-f  n1-standard-1               10.240.0.10  104.197.163.174  RUNNING
etcd1        us-central1-f  n1-standard-1               10.240.0.11  146.148.43.6     RUNNING
etcd2        us-central1-f  n1-standard-1               10.240.0.12  162.222.179.131  RUNNING
worker0      us-central1-f  n1-standard-1               10.240.0.30  104.155.181.141  RUNNING
worker1      us-central1-f  n1-standard-1               10.240.0.31  104.197.163.37   RUNNING
worker2      us-central1-f  n1-standard-1               10.240.0.32  104.154.41.9     RUNNING
````

```
gcloud compute firewall-rules create nginx-service --allow=tcp:32345
```

```
curl http://104.155.181.141:32345
```

```
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```