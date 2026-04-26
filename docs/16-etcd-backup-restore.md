# etcd Backup And Restore

etcd is the source of truth for the cluster. If etcd is lost, Kubernetes loses the desired state of the cluster.

This lab captures a snapshot and shows the restore shape. Practice this before you need it.

## Snapshot

Run this on `server`:

```bash
mkdir -p /var/lib/etcd-backups
etcdctl snapshot save \
  /var/lib/etcd-backups/kubernetes-the-hard-way.db
```

Verify the snapshot:

```bash
etcdutl snapshot status \
  /var/lib/etcd-backups/kubernetes-the-hard-way.db \
  --write-out=table
```

Copy the snapshot off the server:

```bash
scp root@server:/var/lib/etcd-backups/kubernetes-the-hard-way.db .
```

## Restore Shape

Stop the API server and etcd before restoring:

```bash
systemctl stop kube-apiserver
systemctl stop etcd
```

Restore into a new data directory:

```bash
etcdutl snapshot restore \
  /var/lib/etcd-backups/kubernetes-the-hard-way.db \
  --name controller \
  --initial-cluster controller=http://127.0.0.1:2380 \
  --initial-advertise-peer-urls http://127.0.0.1:2380 \
  --data-dir /var/lib/etcd-restore
```

Move the restored data directory into place after saving the old one:

```bash
mv /var/lib/etcd /var/lib/etcd.old
mv /var/lib/etcd-restore /var/lib/etcd
```

Start services again:

```bash
systemctl start etcd
systemctl start kube-apiserver
```

## Modern Cluster Note

For a three-member etcd cluster, snapshot from a healthy member and restore all members with a new initial cluster configuration. Do not restore one member into an existing unhealthy cluster and expect raft membership to repair itself.

Next: [Upgrades](17-upgrades.md)
