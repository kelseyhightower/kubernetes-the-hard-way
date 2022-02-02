## Prerequisites

The commands in this lab must be run on each controller instance: `controller-0`, `controller-1`, and `controller-2`. Login to each controller instance using the `gcloud` command. Example:

```
gcloud compute ssh controller-0
```

## Download certificate management tools

Download the `step` CLI binary and renewal utility for systemd:

```
wget -q --show-progress --https-only --timestamping \
  "https://dl.step.sm/gh-release/cli/gh-release-header/v0.18.0/step_linux_0.18.0_amd64.tar.gz" \
  "https://files.smallstep.com/cert-renewer%40.service" \
  "https://files.smallstep.com/cert-renewer%40.timer"
```

Install the binary and renewal utility files:

```
tar -xvf step_linux_0.18.0_amd64.tar.gz
sudo mv step_0.18.0/bin/step /usr/local/bin/
sudo systemctl daemon-reload
```

### Bootstrapping the CA on your controllers

Run each command on every node:

```
{
STEP_CA_URL=$(gcloud compute project-info describe --format='get(commonInstanceMetadata.items.STEP_CA_URL)')
STEP_CA_FINGERPRINT=$(gcloud compute project-info describe --format='get(commonInstanceMetadata.items.STEP_CA_FINGERPRINT)')
sudo step ca bootstrap \
    --ca-url "${STEP_CA_URL}" \
    --fingerprint "${STEP_CA_FINGERPRINT}"
}
```

Output:

```
The root certificate has been saved in /root/.step/certs/root_ca.crt.
The authority configuration has been saved in /root/.step/config/defaults.json.
```

## Set up the certificate renewal timer

We'll use a systemd timer to renew certificates when they are 2/3rds of the way through their validity period.

Install the systemd certificate renewal service and timer.

```
cat << EOF | sudo tee /etc/systemd/system/cert-renewer@.service
[Unit]
Description=Certificate renewer for %I
After=network-online.target
Documentation=https://smallstep.com/docs/step-ca/certificate-authority-server-production
StartLimitIntervalSec=0

[Service]
Type=oneshot
User=root

Environment=STEPPATH=/etc/step-ca \
            CERT_LOCATION=/etc/step/certs/%i.crt \
            KEY_LOCATION=/etc/step/certs/%i.key

; ExecCondition checks if the certificate is ready for renewal,
; based on the exit status of the command.
; (In systemd <242, you can use ExecStartPre= here.)
ExecCondition=/usr/local/bin/step certificate needs-renewal ${CERT_LOCATION}

; ExecStart renews the certificate, if ExecStartPre was successful.
ExecStart=/usr/local/bin/step ca renew --force ${CERT_LOCATION} ${KEY_LOCATION}

[Install]
WantedBy=multi-user.target
EOF
```

Install the timer:

```
cat << EOF | sudo tee /etc/systemd/system/cert-renewer@.timer
[Unit]
Description=Certificate renewal timer for %I
Documentation=https://smallstep.com/docs/step-ca/certificate-authority-server-production

[Timer]
Persistent=true

; Run the timer unit every 5 minutes.
OnCalendar=*:1/5

; Always run the timer on time.
AccuracySec=1us

; Add jitter to prevent a "thundering hurd" of simultaneous certificate renewals.
RandomizedDelaySec=5m

[Install]
WantedBy=timers.target
EOF
```

## Configure certificate renewal for etcd

Create and start a certificate renewal timer for etcd:

```
sudo mkdir /etc/systemd/system/cert-renewer@etcd.service.d
cat <<EOF | sudo tee /etc/systemd/system/cert-renewer@etcd.service.d/override.conf
[Service]
Environment=STEPPATH=/root/.step \\
            CERT_LOCATION=/etc/etcd/kubernetes.pem \\
            KEY_LOCATION=/etc/etcd/kubernetes-key.pem
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now cert-renewer@etcd.timer
```

## Configure certificate renewal for `kube-controller-manager`

Create and start a certificate renewal timer for `kube-controller-manager`. This one will use `kubectl` to embed the renewed certificate and key into the kubeconfig file before restarting the controller manager. Run:

```
sudo mkdir /etc/systemd/system/cert-renewer@kube-controller-manager.service.d
cat <<EOF | sudo tee /etc/systemd/system/cert-renewer@kube-controller-manager.service.d/override.conf
[Service]
Environment=STEPPATH=/root/.step \\
            CERT_LOCATION=/var/lib/kubernetes/kube-controller-manager.pem
 \\
            KEY_LOCATION=/var/lib/kubernetes/kube-controller-manager-key.pem

ExecStartPost=kubectl config set-credentials system:kube-controller-manager \\
    --client-certificate=\${CERT_LOCATION} \\
    --client-key=\${KEY_LOCATION} \\
    --embed-certs=true \\
    --kubeconfig=/var/lib/kubernetes/kube-controller-manager.kubeconfig

ExecStartPost=systemctl restart kube-controller-manager.service
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now cert-renewer@kube-controller-manager.timer
```

## Configure certificate renewal for kube-scheduler

Create and start a certificate renewal timer for `kube-scheduler`:

```
sudo mkdir /etc/systemd/system/cert-renewer@kube-scheduler.service.d
cat <<EOF | sudo tee /etc/systemd/system/cert-renewer@kube-scheduler.service.d/override.conf
[Service]
Environment=STEPPATH=/root/.step \\
            CERT_LOCATION=/var/lib/kubernetes/kube-scheduler.pem
 \\
            KEY_LOCATION=/var/lib/kubernetes/kube-scheduler-key.pem

ExecStartPost=kubectl config set-credentials system:kube-scheduler \\
    --client-certificate=\${CERT_LOCATION} \\
    --client-key=\${KEY_LOCATION} \\
    --embed-certs=true \\
    --kubeconfig=/var/lib/kubernetes/kube-scheduler.kubeconfig

ExecStartPost=systemctl restart kube-scheduler.service
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now cert-renewer@kube-scheduler.timer
```


## Configure certificate renewal for kube-apiserver

Create and start a certificate renewal timer for `kube-apiserver`:

```
sudo mkdir /etc/systemd/system/cert-renewer@kube-apiserver.service.d
cat <<EOF | sudo tee /etc/systemd/system/cert-renewer@kube-apiserver.service.d/override.conf
[Service]
Environment=STEPPATH=/root/.step \\
            CERT_LOCATION=/var/lib/kubernetes/kubernetes.pem  \\
            KEY_LOCATION=/var/lib/kubernetes/kubernetes-key.pem 

ExecStartPost=systemctl restart kube-apiserver.service
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now cert-renewer@kube-apiserver.timer
```


## Configure service account certificate renewal timer

```
sudo mkdir /etc/systemd/system/cert-renewer@kube-service-account.service.d
cat <<EOF | sudo tee /etc/systemd/system/cert-renewer@kube-service-account.service.d/override.conf
[Service]
Environment=STEPPATH=/root/.step \\
            CERT_LOCATION=/var/lib/kubernetes/service-account.pem
 \\
            KEY_LOCATION=/var/lib/kubernetes/service-account-key.pem

; Restart services that use the service account certificate or key
ExecStartPost=systemctl restart kube-controller-manager.service
ExecStartPost=systemctl restart kube-apiserver.service
sudo systemctl daemon-reload
sudo systemctl enable --now cert-renewer@kube-service-account.timer
EOF
```

> Remember to run the above commands on each controller node: `controller-0`, `controller-1`, and `controller-2`.
