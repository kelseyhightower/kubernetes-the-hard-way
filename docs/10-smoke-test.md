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

Grab the `NodePort` that was setup for the nginx service:

```
NODE_PORT=$(kubectl get svc nginx --output=jsonpath='{range .spec.ports[0]}{.nodePort}')
```

### Create the Node Port Firewall Rule

#### GCP

```
gcloud compute firewall-rules create kubernetes-nginx-service \
  --allow=tcp:${NODE_PORT} \
  --network kubernetes
```

Grab the `EXTERNAL_IP` for one of the worker nodes:

```
NODE_PUBLIC_IP=$(gcloud compute instances describe worker0 \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')
```

#### AWS

```
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=kubernetes" | \
  jq -r '.SecurityGroups[].GroupId')
```

```
aws ec2 authorize-security-group-ingress \
  --group-id ${SECURITY_GROUP_ID} \
  --protocol tcp \
  --port ${NODE_PORT} \
  --cidr 0.0.0.0/0
```

Grab the `EXTERNAL_IP` for one of the worker nodes:

```
NODE_PUBLIC_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=worker0" | \
  jq -j '.Reservations[].Instances[].PublicIpAddress')
```

---

Test the nginx service using cURL:

```
curl http://${NODE_PUBLIC_IP}:${NODE_PORT}
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
