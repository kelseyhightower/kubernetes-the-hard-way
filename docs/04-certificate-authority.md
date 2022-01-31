# Provisioning a CA

In this lab you will provision a [PKI Infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure) using Smallstep's CA server, [`step-ca`](https://github.com/smallstep/certificates), and generate TLS certificates for the following components: etcd, kube-apiserver, kube-controller-manager, kube-scheduler, kubelet, and kube-proxy.

## Certificate Authority

In this section you will provision a `step-ca` Certificate Authority that can be used to generate additional TLS certificates. The CA will only run on `controller-0`. While it's possible to run a high-availability CA across multiple nodes, it's not necessary in a small-to-medium sized Kubernetes cluster. The CA service would have to be down for several days before having any negative impact on the cluster.

Connect to `controller-0`:

```
gcloud compute ssh controller-0
```

Download the `step` client and `step-ca` server binaries, and the `jq` command:

```
{
wget -q --show-progress --https-only --timestamping \
  "https://dl.step.sm/gh-release/certificates/gh-release-header/v0.18.0/step-ca_linux_0.18.0_amd64.tar.gz"
wget -q --show-progress --https-only --timestamping \
  "https://dl.step.sm/gh-release/cli/gh-release-header/v0.18.0/step_linux_0.18.0_amd64.tar.gz"
sudo apt update
sudo apt install -y jq
}
```

Install the binaries:

```
{
tar -xvf step-ca_linux_0.18.0_amd64.tar.gz
sudo mv step-ca_0.18.0/bin/* /usr/local/bin/
tar -xvf step_linux_0.18.0_amd64.tar.gz
sudo mv step_0.18.0/bin/* /usr/local/bin/
}
```

Now create a `step` user and the paths for `step-ca`:

```
{
sudo useradd --system --home /etc/step-ca --shell /bin/false step
}
```

Create a CA configuration folder and generate passwords for the CA root key and the CA provisioner:

```
{
export STEPPATH=/etc/step-ca
umask 077
sudo mkdir -p $(step path)/db
< /dev/urandom tr -dc A-Za-z0-9 | head -c40 | sudo tee $(step path)/password > /dev/null
< /dev/urandom tr -dc A-Za-z0-9 | head -c40  > provisioner-password
umask 002
}
```

Initialize your PKI:

```
{
INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)
INTERNAL_HOSTNAME=$(hostname -f)
sudo -E step ca init --name="admin" \
   --dns="$INTERNAL_IP,$INTERNAL_HOSTNAME,$EXTERNAL_IP" \
   --address=":4443" --provisioner="kubernetes" \
   --password-file="$(step path)/password" \
   --provisioner-password-file="provisioner-password"
sudo -E step ca provisioner add acme --type ACME
}
```

Configure the CA provisioner to issue 90-day certificates:

```
{
sudo jq '(.authority.provisioners[]) += {
            "claims": {
               "maxTLSCertDuration": "2160h",
               "defaultTLSCertDuration": "2160h"
        }
}' /etc/step-ca/config/ca.json > ca-new.json
sudo mv ca-new.json /etc/step-ca/config/ca.json
}
```

Put the CA configuration into place, and add the CA to systemd:

```
{
sudo chown -R step:step /etc/step-ca
cat <<EOF | sudo tee /etc/systemd/system/step-ca.service
[Unit]
Description=step-ca service
Documentation=https://smallstep.com/docs/step-ca
Documentation=https://smallstep.com/docs/step-ca/certificate-authority-server-production
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=30
StartLimitBurst=3
ConditionFileNotEmpty=/etc/step-ca/config/ca.json
ConditionFileNotEmpty=/etc/step-ca/password

[Service]
Type=simple
User=step
Group=step
Environment=STEPPATH=/etc/step-ca
WorkingDirectory=/etc/step-ca
ExecStart=/usr/local/bin/step-ca config/ca.json --password-file password
ExecReload=/bin/kill --signal HUP $MAINPID
Restart=on-failure
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=30
StartLimitBurst=3

; Process capabilities & privileges
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
SecureBits=keep-caps
NoNewPrivileges=yes

; Sandboxing
ProtectSystem=full
ProtectHome=true
RestrictNamespaces=true
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
PrivateTmp=true
ProtectClock=true
ProtectControlGroups=true
ProtectKernelTunables=true
ProtectKernelLogs=true
ProtectKernelModules=true
LockPersonality=true
RestrictSUIDSGID=true
RemoveIPC=true
RestrictRealtime=true
PrivateDevices=true
SystemCallFilter=@system-service
SystemCallArchitectures=native
MemoryDenyWriteExecute=true
ReadWriteDirectories=/etc/step-ca/db

[Install]
WantedBy=multi-user.target
EOF
}
```

Save the root CA certificate:

```
sudo cat /etc/step-ca/certs/root_ca.crt | tee ca.pem > /dev/null
```

Finally, start the CA service:

```
{
sudo systemctl daemon-reload
sudo systemctl enable --now step-ca
}
```

## Verification

Check the CA health, then request and save the CA root certificate:

```
sudo -u step -E step ca health
```

Output:

```
ok
```

You can now sign out of `controller-0`.

# Generating certificates

## Bootstrapping with the CA

### Bootstrapping your local machine

Run the following on your local machine.

Download your CA's root certificate:

```
gcloud compute scp controller-0:ca.pem controller-0:provisioner-password .
```

Result:

```
ca.pem
provisioner-password
```

Now bootstrap with your CA:

```
{
CA_IP=$(gcloud compute instances describe controller-0 \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
step ca bootstrap --ca-url "https://$CA_IP:4443/" --fingerprint $(step certificate fingerprint ca.pem)
}
```

Output:

```
The root certificate has been saved in /home/carl/.step/authorities/XX.XXX.XXX.XXX/certs/root_ca.crt.
The authority configuration has been saved in /home/carl/.step/authorities/XX.XXX.XXX.XXX/config/defaults.json.
The profile configuration has been saved in /home/carl/.step/profiles/XX.XXX.XXX.XXX/config/defaults.json.
```

Add your CA URL and fingerprint to the project metadata on GCP, so instances can bootstrap:

```
gcloud compute project-info add-metadata --metadata="STEP_CA_URL=https://10.240.0.10:4443,STEP_CA_FINGERPRINT=$(step certificate fingerprint ca.pem)"
```

Output:

```
Updated [https://www.googleapis.com/compute/v1/projects/project-id-xxxxxx].
```

### Bootstrapping remote instances


Run each command on every node:

```
{
for i in 0 1 2; do
  gcloud compute ssh worker-${i} -- \
    step ca bootstrap \
        --ca-url "$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/project/attributes/STEP_CA_URL)" \
        --fingerprint "$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/project/attributes/STEP_CA_FINGERPRINT)"
  gcloud compute ssh worker-${i} -- \
    step ca bootstrap \
        --ca-url "$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/project/attributes/STEP_CA_URL)" \
        --fingerprint "$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/project/attributes/STEP_CA_FINGERPRINT)"
done
}
```

Output:

```
The root certificate has been saved in /home/carl/.step/certs/root_ca.crt.
The authority configuration has been saved in /home/carl/.step/config/defaults.json.
```


## Client and Server Certificates

In this section you will generate client and server certificates for each Kubernetes component and a client certificate for the Kubernetes `admin` user.

### The Admin Client Certificate

On your local machine, generate the `admin` client certificate and private key:

```
{
step ca certificate admin admin.pem admin-key.pem \
  --provisioner="kubernetes" \
  --provisioner-password-file="provisioner-password"
}
```

Results:

```
admin-key.pem
admin.pem
```

### The Kubelet Client Certificates

Kubernetes uses a [special-purpose authorization mode](https://kubernetes.io/docs/admin/authorization/node/) called Node Authorizer, that specifically authorizes API requests made by [Kubelets](https://kubernetes.io/docs/concepts/overview/components/#kubelet). In order to be authorized by the Node Authorizer, Kubelets must use a credential that identifies them as being in the `system:nodes` group, with a username of `system:node:<nodeName>`. In this section you will create a certificate for each Kubernetes worker node that meets the Node Authorizer requirements.

Generate a certificate and private key for each Kubernetes worker node:

```
for instance in worker-0 worker-1 worker-2; do

EXTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

INTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].networkIP)')

step ca certificate "system:node:${instance}" ${instance}.pem ${instance}-key.pem --san "${instance}" --san "${EXTERNAL_IP}" --san "${INTERNAL_IP}" --provisioner "kubernetes" --provisioner-password-file "provisioner-password"
done
```

Results:

```
worker-0-key.pem
worker-0.pem
worker-1-key.pem
worker-1.pem
worker-2-key.pem
worker-2.pem
```













### The Controller Manager Client Certificate

Generate the `kube-controller-manager` client certificate and private key:

```
{

cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

}
```

Results:

```
kube-controller-manager-key.pem
kube-controller-manager.pem
```


### The Kube Proxy Client Certificate

Generate the `kube-proxy` client certificate and private key:

```
{

cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

}
```

Results:

```
kube-proxy-key.pem
kube-proxy.pem
```

### The Scheduler Client Certificate

Generate the `kube-scheduler` client certificate and private key:

```
{

cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

}
```

Results:

```
kube-scheduler-key.pem
kube-scheduler.pem
```


### The Kubernetes API Server Certificate

The `kubernetes-the-hard-way` static IP address will be included in the list of subject alternative names for the Kubernetes API Server certificate. This will ensure the certificate can be validated by remote clients.

Generate the Kubernetes API Server certificate and private key:

```
{

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.240.0.10,10.240.0.11,10.240.0.12,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

}
```

> The Kubernetes API server is automatically assigned the `kubernetes` internal dns name, which will be linked to the first IP address (`10.32.0.1`) from the address range (`10.32.0.0/24`) reserved for internal cluster services during the [control plane bootstrapping](08-bootstrapping-kubernetes-controllers.md#configure-the-kubernetes-api-server) lab.

Results:

```
kubernetes-key.pem
kubernetes.pem
```

## The Service Account Key Pair

The Kubernetes Controller Manager leverages a key pair to generate and sign service account tokens as described in the [managing service accounts](https://kubernetes.io/docs/admin/service-accounts-admin/) documentation.

Generate the `service-account` certificate and private key:

```
{

cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account

}
```

Results:

```
service-account-key.pem
service-account.pem
```


## Distribute the Client and Server Certificates

Copy the appropriate certificates and private keys to each worker instance:

```
for instance in worker-0 worker-1 worker-2; do
  gcloud compute scp ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/
done
```

Copy the appropriate certificates and private keys to each controller instance:

```
for instance in controller-0 controller-1 controller-2; do
  gcloud compute scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem ${instance}:~/
done
```

> The `kube-proxy`, `kube-controller-manager`, `kube-scheduler`, and `kubelet` client certificates will be used to generate client authentication configuration files in the next lab.

Next: [Generating Kubernetes Configuration Files for Authentication](05-kubernetes-configuration-files.md)
