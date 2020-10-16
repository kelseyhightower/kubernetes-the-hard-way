

# 1. Get etcdctl utility if it's not already present.

Reference: https://github.com/etcd-io/etcd/releases

```
ETCD_VER=v3.4.9

# choose either URL
GOOGLE_URL=https://storage.googleapis.com/etcd
GITHUB_URL=https://github.com/etcd-io/etcd/releases/download
DOWNLOAD_URL=${GOOGLE_URL}

rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
rm -rf /tmp/etcd-download-test && mkdir -p /tmp/etcd-download-test

curl -L ${DOWNLOAD_URL}/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz
tar xzvf /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz -C /tmp/etcd-download-test --strip-components=1
rm -f /tmp/etcd-${ETCD_VER}-linux-amd64.tar.gz

/tmp/etcd-download-test/etcd --version
ETCDCTL_API=3 /tmp/etcd-download-test/etcdctl version

mv /tmp/etcd-download-test/etcdctl /usr/bin
```

# 2. Backup

```
ETCDCTL_API=3 etcdctl --endpoints=https://[127.0.0.1]:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key \
     snapshot save /opt/snapshot-pre-boot.db
```

# -----------------------------
# Disaster Happens
# -----------------------------

# 3. Restore ETCD Snapshot to a new folder

```
ETCDCTL_API=3 etcdctl --endpoints=https://[127.0.0.1]:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key \
     --data-dir /var/lib/etcd-from-backup \
     snapshot restore /opt/snapshot-pre-boot.db
```

# 4. Modify /etc/kubernetes/manifests/etcd.yaml

Update ETCD POD to use the new hostPath directory `/var/lib/etcd-from-backup` by modifying the pod definition file at `/etc/kubernetes/manifests/etcd.yaml`. When this file is updated, the ETCD pod is automatically re-created as this is a static pod placed under the `/etc/kubernetes/manifests` directory.


Update volumes and volume mounts to point to new path

```
  volumes:
  - hostPath:
      path: /var/lib/etcd-from-backup
      type: DirectoryOrCreate
    name: etcd-data
  - hostPath:
      path: /etc/kubernetes/pki/etcd
      type: DirectoryOrCreate
    name: etcd-certs
```

> Note: as the ETCD pod has changed it will automatically restart, and also kube-controller-manager and kube-scheduler. Wait 1-2 to mins for this pods to restart. You can make a `watch "docker ps | grep etcd"` to see when the ETCD pod is restarted.

> Note2: If the etcd pod is not getting `Ready 1/1`, then restart it by `kubectl delete pod -n kube-system etcd-controlplane` and wait 1 minute.
