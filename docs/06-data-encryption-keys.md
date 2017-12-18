# Generating the Data Encryption Config and Key

Kubernetes stores a variety of data including cluster state, application configurations, and secrets. Kubernetes supports the ability to [encrypt](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data) cluster data at rest.

In this lab you will generate an encryption key and an [encryption config](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#understanding-the-encryption-at-rest-configuration) suitable for encrypting Kubernetes Secrets.

## The Encryption Key

Generate an encryption key:

#### Linux & OS X
```
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

#### Windows
```
$ENCRYPTION_KEY=[System.Convert]::ToBase64String($(0..31 | ForEach-Object { Get-Random -Minimum 0 -Maximum 255 } ))
```

## The Encryption Config File

Create the `encryption-config.yaml` encryption config file:

#### Linux & OS X
```
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

#### Windows
```
New-Item encryption-config.yaml -Value @"
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
"@
```

Copy the `encryption-config.yaml` encryption config file to each controller instance:

#### Linux & OS X
```
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp encryption-config.yaml ${instance}:~/
done
```

#### Windows
```
@('controller-0','controller-1','controller-2') | ForEach-Object {
  gcloud compute scp encryption-config.yaml ${_}:/home/$env:USERNAME/
}
```

Next: [Bootstrapping the etcd Cluster](07-bootstrapping-etcd.md)
