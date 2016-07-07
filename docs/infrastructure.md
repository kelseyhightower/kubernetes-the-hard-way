# Infrastructure

```
gcloud compute addresses create kubernetes
```

```
146.148.34.151
```

## etcd

```
gcloud compute instances create etcd0 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --private-network-ip 10.240.0.10
```

```
gcloud compute instances create etcd1 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --private-network-ip 10.240.0.11
```

```
gcloud compute instances create etcd2 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --private-network-ip 10.240.0.12
```

## Kubernetes Control Plane

```
gcloud compute instances create controller0 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --private-network-ip 10.240.0.20
```

```
gcloud compute instances create controller1 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --private-network-ip 10.240.0.21
```

```
gcloud compute instances create controller2 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --private-network-ip 10.240.0.22
```

## Kubernetes Workers

```
gcloud compute instances create worker0 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --private-network-ip 10.240.0.30
```

```
gcloud compute instances create worker1 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --private-network-ip 10.240.0.31
```

```
gcloud compute instances create worker2 \
 --boot-disk-size 200GB \
 --can-ip-forward \
 --image-project ubuntu-os-cloud \
 --image ubuntu-1604-xenial-v20160627 \
 --machine-type n1-standard-1 \
 --private-network-ip 10.240.0.32
```

### Verify

```
gcloud compute instances list
```

````
NAME         ZONE           MACHINE_TYPE   INTERNAL_IP  STATUS
controller0  us-central1-f  n1-standard-1  10.240.0.20  RUNNING
controller1  us-central1-f  n1-standard-1  10.240.0.21  RUNNING
controller2  us-central1-f  n1-standard-1  10.240.0.22  RUNNING
etcd0        us-central1-f  n1-standard-1  10.240.0.10  RUNNING
etcd1        us-central1-f  n1-standard-1  10.240.0.11  RUNNING
etcd2        us-central1-f  n1-standard-1  10.240.0.12  RUNNING
worker0      us-central1-f  n1-standard-1  10.240.0.30  RUNNING
worker1      us-central1-f  n1-standard-1  10.240.0.31  RUNNING
worker2      us-central1-f  n1-standard-1  10.240.0.32  RUNNING
````