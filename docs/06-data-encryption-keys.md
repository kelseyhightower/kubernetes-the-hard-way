# Generating the Data Encryption Config and Key

Kubernetes stores a variety of data including cluster state, application configurations, and secrets. Kubernetes supports the ability to [encrypt](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data) cluster data at rest.

In this lab you will generate an encryption key and an [encryption config](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#understanding-the-encryption-at-rest-configuration) suitable for encrypting Kubernetes Secrets.

## The Encryption Key

Generate an encryption key:

```
$ ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

## The Encryption Config File

Create the `encryption-config.yaml` encryption config file:

```
$ cat > encryption-config.yaml <<EOF
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

Copy the `encryption-config.yaml` encryption config file to each master instance:

```
$ aws ec2 describe-instances --filters Name=vpc-id,Values=vpc-xxxxxxxxxxxxxxxxx \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value | [0],InstanceId,Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress,State.Name]' \
  --output text | sort | grep master
master-0        i-xxxxxxxxxxxxxxxxx     ap-northeast-1c 10.240.0.10     xx.xxx.xxx.xxx  running
master-1        i-yyyyyyyyyyyyyyyyy     ap-northeast-1c 10.240.0.11     yy.yyy.yyy.yy   running
master-2        i-zzzzzzzzzzzzzzzzz     ap-northeast-1c 10.240.0.12     zz.zzz.z.zzz    running

for masternode in xx.xxx.xxx.xxx yy.yyy.yyy.yy zz.zzz.z.zzz; do
  scp -i ~/.ssh/your_ssh_key \
    encryption-config.yaml \
    ubuntu@${masternode}:~/
done
```

Next: [Bootstrapping the etcd Cluster](07-bootstrapping-etcd.md)