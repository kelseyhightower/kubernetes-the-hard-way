# Configuring Certificate Renewal

## Prerequisites

The commands in this section must be run on every instance: `controller-0`, `controller-1`, `controller-2`, `worker-0`, `worker-1`, and `worker-2`. Login to each instance using the `gcloud` command. Example:

```
gcloud compute ssh controller-0
```

## Download certificate management tools

Run each command on every node.

Download the `step` CLI binary:

```
wget -q --show-progress --https-only --timestamping \
  "https://dl.step.sm/gh-release/cli/gh-release-header/v0.20.0/step_linux_0.20.0_amd64.tar.gz"
```

Install the binary:

```
tar -xvf step_linux_0.20.0_amd64.tar.gz
sudo mv step_0.20.0/bin/step /usr/local/bin/
```

## Bootstrap with the CA

Configure the host to trust your Certificate Authority:

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

Environment=STEPPATH=/etc/step-ca \\
            CERT_LOCATION=/etc/step/certs/%i.crt \\
            KEY_LOCATION=/etc/step/certs/%i.key

; ExecCondition checks if the certificate is ready for renewal,
; based on the exit status of the command.
; (In systemd <242, you can use ExecStartPre= here.)
ExecCondition=/usr/local/bin/step certificate needs-renewal \${CERT_LOCATION}

; ExecStart renews the certificate, if ExecStartPre was successful.
ExecStart=/usr/local/bin/step ca renew --force \${CERT_LOCATION} \${KEY_LOCATION}

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

# Controller Certificate Renewal

## Prerequisites

The commands in this section must be run on every controller: `controller-0`, `controller-1`, `controller-2`. Login to each instance using the `gcloud` command. Example:

```
gcloud compute ssh controller-0
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
            CERT_LOCATION=/var/lib/kubernetes/kube-controller-manager.pem \\
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
            CERT_LOCATION=/var/lib/kubernetes/kube-scheduler.pem \\
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

The service account certificate and key is used by the API server, so we will need to restart it when the certificate file is updated:

```
sudo mkdir /etc/systemd/system/cert-renewer@kube-service-account.service.d
cat <<EOF | sudo tee /etc/systemd/system/cert-renewer@kube-service-account.service.d/override.conf
[Service]
Environment=STEPPATH=/root/.step \\
            CERT_LOCATION=/var/lib/kubernetes/service-account.pem \\
            KEY_LOCATION=/var/lib/kubernetes/service-account-key.pem

; Restart services that use the service account certificate or key
ExecStartPost=systemctl restart kube-apiserver.service
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now cert-renewer@kube-service-account.timer
```

> Remember to run the above commands on each controller node: `controller-0`, `controller-1`, and `controller-2`.

# Worker Certificate Renewal

## Prerequisites

The commands in this section must be run on every worker: `worker-0`, `worker-1`, and `worker-2`. Login to each instance using the `gcloud` command. Example:

```
gcloud compute ssh worker-0
```

## Configure Certificate Renewal for `kubelet.service`

Install the a renewal service that will restart `kubelet.service` when the certificate is renewed:

```
sudo mkdir /etc/systemd/system/cert-renewer@kubelet.service.d
cat <<EOF | sudo tee /etc/systemd/system/cert-renewer@kubelet.service.d/override.conf
[Service]
Environment=STEPPATH=/root/.step \\
            CERT_LOCATION=/var/lib/kubelet/${HOSTNAME}.pem \\
            KEY_LOCATION=/var/lib/kubelet/${HOSTNAME}-key.pem

; Restart services that use the service account certificate or key
ExecStartPost=systemctl restart kubelet.service
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now cert-renewer@kubelet.timer
```

## Configure Certificate Renewal for `kube-proxy.service`

Install a renewal service that will rebuild the kubeconfig file and restart kube-proxy when the certificate is renewed:

```
sudo mkdir /etc/systemd/system/cert-renewer@kube-proxy.service.d
cat <<EOF | sudo tee /etc/systemd/system/cert-renewer@kube-proxy.service.d/override.conf
[Service]
Environment=STEPPATH=/root/.step \\
            CERT_LOCATION=/var/lib/kube-proxy/kube-proxy.pem \\
            KEY_LOCATION=/var/lib/kube-proxy/kube-proxy.pem

ExecStartPost=kubectl config set-credentials system:kube-proxy \\
    --client-certificate=\${CERT_LOCATION} \\
    --client-key=\${KEY_LOCATION} \\
    --embed-certs=true \\
    --kubeconfig=/var/lib/kube-proxy/kubeconfig

ExecStartPost=systemctl restart kube-proxy.service
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now cert-renewer@kube-proxy.timer
```


> Remember to run the above commands on each controller node: `worker-0`, `worker-1`, and `worker-2`.
