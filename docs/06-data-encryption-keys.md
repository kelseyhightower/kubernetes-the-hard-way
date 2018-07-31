# Generating the Data Encryption Config and Key

Kubernetes stores a variety of data including cluster state, application configurations, and secrets. Kubernetes supports the ability to [encrypt](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data) cluster data at rest.

In this lab you will generate an encryption key and an [encryption config](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#understanding-the-encryption-at-rest-configuration) suitable for encrypting Kubernetes Secrets.

## The Encryption Key

Generate an encryption key:

```
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

## The Encryption Config File

Create the `encryption-config.yaml` encryption config file:

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

Copy the `encryption-config.yaml` encryption config file to each controller instance:

<details open>
<summary>GCP</summary>

```
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp encryption-config.yaml ${instance}:~/
done
```

</details>

<details>
<summary>AWS</summary>

```
VPC_ID="$(aws ec2 describe-vpcs \
  --filters Name=tag-key,Values=kubernetes.io/cluster/kubernetes-the-hard-way \
  --profile kubernetes-the-hard-way \
  --query 'Vpcs[0].VpcId' \
  --output text)"

get_ip() {
  aws ec2 describe-instances \
    --filters \
      Name=vpc-id,Values="$VPC_ID" \
      Name=tag:Name,Values="$1" \
    --profile kubernetes-the-hard-way \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text
}
```
```
for instance in controller-0 controller-1 controller-2; do
  scp -i ~/.ssh/kubernetes-the-hard-way -o StrictHostKeyChecking=no \
    encryption-config.yaml "ubuntu@$(get_ip "$instance"):~/"
done
```

</details>
<p></p>

Next: [Bootstrapping the etcd Cluster](07-bootstrapping-etcd.md)
