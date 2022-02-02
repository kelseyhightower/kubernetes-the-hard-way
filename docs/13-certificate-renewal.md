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
sudo mv step_0.18.0/bin/* /usr/local/bin/
sudo mv cert-renewer@.service /etc/systemd/system
sudo mv cert-renewer@.timer /etc/systemd/system
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

## Configure certificate renewal for etcd

Create and start a certificate renewal timer for etcd:

```
sudo mkdir /etc/systemd/system/cert-renewer@etcd.service.d
cat <<EOF | sudo tee /etc/systemd/system/cert-renewer@etcd.service.d/override.conf
[Service]
Environment=STEPPATH=/root/.step \\
            CERT_LOCATION=/etc/etcd/kubernetes.pem \\
            KEY_LOCATION=/etc/etcd/kubernetes-key.pem

; Don't try to restart etcd.service; etcd will read
; certificates from disk on every new request.
ExecStartPost=
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now cert-renewer@etcd.timer
```

## Configure certificate renewal for kube-controller-manager



## Configure certificate renewal for kube-scheduler


> Remember to run the above commands on each controller node: `controller-0`, `controller-1`, and `controller-2`.
