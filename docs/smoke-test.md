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