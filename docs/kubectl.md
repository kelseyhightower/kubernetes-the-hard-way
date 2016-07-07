# Configuring Kubectl

## OS X

```
gcloud compute copy-files \
  controller0:~/kubernetes/platforms/darwin/amd64/kubectl .
```

## Linux

```
gcloud compute copy-files \
  controller0:~/kubernetes/platforms/linux/amd64/kubectl .
```

```
sudo mv kubectl /usr/local/bin/
```

```
gcloud compute http-health-checks create basic-check
```

```
gcloud compute target-pools create kubernetes \
    --region us-central1 --health-check basic-check
```