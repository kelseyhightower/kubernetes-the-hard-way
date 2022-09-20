# Generating the Data Encryption Config and Key

Kubernetes stores a variety of data including cluster state, application configurations, and secrets. Kubernetes supports the ability to [encrypt](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data) cluster data at rest, that is, the data stored within `etcd`.

In this lab you will generate an encryption key and an [encryption config](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#understanding-the-encryption-at-rest-configuration) suitable for encrypting Kubernetes Secrets.

## The Encryption Key

[//]: # (host:master-1)

Generate an encryption key:

```bash
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

## The Encryption Config File

Create the `encryption-config.yaml` encryption config file:

```bash
cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
```

Copy the `encryption-config.yaml` encryption config file to each controller instance:

```bash
for instance in master-1 master-2; do
  scp encryption-config.yaml ${instance}:~/
done
```

Move `encryption-config.yaml` encryption config file to appropriate directory.

```bash
for instance in master-1 master-2; do
  ssh ${instance} sudo mkdir -p /var/lib/kubernetes/
  ssh ${instance} sudo mv encryption-config.yaml /var/lib/kubernetes/
done
```

Reference: https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#encrypting-your-data

Prev: [Generating Kubernetes Configuration Files for Authentication](05-kubernetes-configuration-files.md)<br>
Next: [Bootstrapping the etcd Cluster](07-bootstrapping-etcd.md)
