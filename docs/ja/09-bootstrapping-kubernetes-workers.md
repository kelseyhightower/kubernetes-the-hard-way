# Kubernetesワーカーノードのブートストラップ

このラボでは、2つのKubernetesワーカーノードをブートストラップします。以下のコンポーネントがインストールされます: [runc](https://github.com/opencontainers/runc), [container networking plugins](https://github.com/containernetworking/cni), [containerd](https://github.com/containerd/containerd), [kubelet](https://kubernetes.io/docs/admin/kubelet), および [kube-proxy](https://kubernetes.io/docs/concepts/cluster-administration/proxies)。

## 前提条件

Kubernetesバイナリとsystemdユニットファイルを各ワーカーインスタンスにコピーします:

```bash
for host in node-0 node-1; do
  SUBNET=$(grep $host machines.txt | cut -d " " -f 4)
  sed "s|SUBNET|$SUBNET|g" \
    configs/10-bridge.conf > 10-bridge.conf

  sed "s|SUBNET|$SUBNET|g" \
    configs/kubelet-config.yaml > kubelet-config.yaml

  scp 10-bridge.conf kubelet-config.yaml \
  root@$host:~/
done
```

```bash
for host in node-0 node-1; do
  scp \
    downloads/runc.arm64 \
    downloads/crictl-v1.28.0-linux-arm.tar.gz \
    downloads/cni-plugins-linux-arm64-v1.3.0.tgz \
    downloads/containerd-1.7.8-linux-arm64.tar.gz \
    downloads/kubectl \
    downloads/kubelet \
    downloads/kube-proxy \
    configs/99-loopback.conf \
    configs/containerd-config.toml \
    configs/kube-proxy-config.yaml \
    units/containerd.service \
    units/kubelet.service \
    units/kube-proxy.service \
    root@$host:~/
done
```

このラボのコマンドは各ワーカーインスタンス（`node-0`、`node-1`）で実行する必要があります。`ssh`コマンドを使用してワーカーインスタンスにログインします。例:

```bash
ssh root@node-0
```

## Kubernetesワーカーノードのプロビジョニング

OS依存関係をインストールします:

```bash
{
  apt-get update
  apt-get -y install socat conntrack ipset
}
```

> socatバイナリは`kubectl port-forward`コマンドのサポートを有効にします。

### スワップの無効化

デフォルトでは、[swap](https://help.ubuntu.com/community/SwapFaq)が有効になっているとkubeletは起動に失敗します。Kubernetesが適切なリソース割り当てとサービス品質を提供できるようにするために、スワップを無効にすることが[推奨](https://github.com/kubernetes/kubernetes/issues/7294)されています。

スワップが有効かどうかを確認します:

```bash
swapon --show
```

出力が空であればスワップは有効ではありません。スワップが有効であれば、次のコマンドを実行してスワップを即座に無効にします:

```bash
swapoff -a
```

> 再起動後もスワップが無効のままであることを確認するには、Linuxディストリビューションのドキュメントを参照してください。

インストールディレクトリを作成します:

```bash
mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

ワーカーバイナリをインストールします:

```bash
{
  mkdir -p containerd
  tar -xvf crictl-v1.28.0-linux-arm.tar.gz
  tar -xvf containerd-1.7.8-linux-arm64.tar.gz -C containerd
  tar -xvf cni-plugins-linux-arm64-v1.3.0.tgz -C /opt/cni/bin/
  mv runc.arm64 runc
  chmod +x crictl kubectl kube-proxy kubelet runc
  mv crictl kubectl kube-proxy kubelet runc /usr/local/bin/
  mv containerd/bin/* /bin/
}
```

### CNIネットワークの構成

`bridge`ネットワーク構成ファイルを作成します:

```bash
mv 10-bridge.conf 99-loopback.conf /etc/cni/net.d/
```

### containerdの構成

`containerd`構成ファイルをインストールします:

```bash
{
  mkdir -p /etc/containerd/
  mv containerd-config.toml /etc/containerd/config.toml
  mv containerd.service /etc/systemd/system/
}
```

### kubeletの構成

`kubelet-config.yaml`構成ファイルを作成します:

```bash
{
  mv kubelet-config.yaml /var/lib/kubelet/
  mv kubelet.service /etc/systemd/system/
}
```

### Kubernetesプロキシの構成

```bash
{
  mv kube-proxy-config.yaml /var/lib/kube-proxy/
  mv kube-proxy.service /etc/systemd/system/
}
```

### ワーカーサービスの起動

```bash
{
  systemctl daemon-reload
  systemctl enable containerd kubelet kube-proxy
  systemctl start containerd kubelet kube-proxy
}
```

## 検証

このチュートリアルのコンピュートインスタンスではこのセクションを完了する権限がありません。`jumpbox`マシンから次のコマンドを実行してください。

登録されているKubernetesノードをリストします:

```bash
ssh root@server \
  "kubectl get nodes \
  --kubeconfig admin.kubeconfig"
```

```
NAME     STATUS   ROLES    AGE    VERSION
node-0   Ready    <none>   1m     v1.28.3
node-1   Ready    <none>   10s    v1.28.3
```

次: [リモートアクセス用のkubectlの構成](10-configuring-kubectl.md)
