# Kubernetesコントロールプレーンのブートストラップ

このラボでは、Kubernetesコントロールプレーンをブートストラップします。以下のコンポーネントがコントローラーマシンにインストールされます：Kubernetes API Server、Scheduler、およびController Manager。

## 前提条件

Kubernetesバイナリとsystemdユニットファイルを`server`インスタンスにコピーします：

```bash
scp \
  downloads/kube-apiserver \
  downloads/kube-controller-manager \
  downloads/kube-scheduler \
  downloads/kubectl \
  units/kube-apiserver.service \
  units/kube-controller-manager.service \
  units/kube-scheduler.service \
  configs/kube-scheduler.yaml \
  configs/kube-apiserver-to-kubelet.yaml \
  root@server:~/
```

このラボのコマンドはすべてコントローラーインスタンス`server`上で実行する必要があります。`ssh`コマンドを使用してコントローラーインスタンスにログインします。例：

```bash
ssh root@server
```

## Kubernetesコントロールプレーンのプロビジョニング

Kubernetes構成ディレクトリを作成します：

```bash
mkdir -p /etc/kubernetes/config
```

### Kubernetesコントローラーバイナリのインストール

Kubernetesバイナリをインストールします：

```bash
{
  chmod +x kube-apiserver \
    kube-controller-manager \
    kube-scheduler kubectl

  mv kube-apiserver \
    kube-controller-manager \
    kube-scheduler kubectl \
    /usr/local/bin/
}
```

### Kubernetes API Serverの構成

```bash
{
  mkdir -p /var/lib/kubernetes/

  mv ca.crt ca.key \
    kube-api-server.key kube-api-server.crt \
    service-accounts.key service-accounts.crt \
    encryption-config.yaml \
    /var/lib/kubernetes/
}
```

`kube-apiserver.service` systemdユニットファイルを作成します：

```bash
mv kube-apiserver.service \
  /etc/systemd/system/kube-apiserver.service
```

### Kubernetes Controller Managerの構成

`kube-controller-manager` kubeconfigを適切な場所に移動します：

```bash
mv kube-controller-manager.kubeconfig /var/lib/kubernetes/
```

`kube-controller-manager.service` systemdユニットファイルを作成します：

```bash
mv kube-controller-manager.service /etc/systemd/system/
```

### Kubernetes Schedulerの構成

`kube-scheduler` kubeconfigを適切な場所に移動します：

```bash
mv kube-scheduler.kubeconfig /var/lib/kubernetes/
```

`kube-scheduler.yaml`構成ファイルを作成します：

```bash
mv kube-scheduler.yaml /etc/kubernetes/config/
```

`kube-scheduler.service` systemdユニットファイルを作成します：

```bash
mv kube-scheduler.service /etc/systemd/system/
```

### コントローラーサービスの起動

```bash
{
  systemctl daemon-reload

  systemctl enable kube-apiserver \
    kube-controller-manager kube-scheduler

  systemctl start kube-apiserver \
    kube-controller-manager kube-scheduler
}
```

> Kubernetes API Serverの完全な初期化まで最大10秒かかる場合があります。

### 検証

```bash
kubectl cluster-info \
  --kubeconfig admin.kubeconfig
```

```text
Kubernetesコントロールプレーンはhttps://127.0.0.1:6443で実行中です
```

## Kubelet認可のためのRBAC

このセクションでは、Kubernetes API Serverが各ワーカーノードのKubelet APIにアクセスできるようにRBAC権限を構成します。Kubelet APIへのアクセスは、メトリクスの取得、ログの取得、およびポッドでのコマンドの実行に必要です。

> このチュートリアルでは、Kubeletの`--authorization-mode`フラグを`Webhook`に設定します。Webhookモードでは、[SubjectAccessReview](https://kubernetes.io/docs/admin/authorization/#checking-api-access) APIを使用して認可を決定します。

このセクションのコマンドは、クラスタ全体に影響を与えるため、コントローラーノード上で実行する必要があります。

```bash
ssh root@server
```

`system:kube-apiserver-to-kubelet` [ClusterRole](https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole)を作成し、Kubelet APIへのアクセス権限とポッドの管理に関連するタスクの実行権限を付与します：

```bash
kubectl apply -f kube-apiserver-to-kubelet.yaml \
  --kubeconfig admin.kubeconfig
```

### 検証

この時点で、Kubernetesコントロールプレーンが稼働しています。`jumpbox`マシンから以下のコマンドを実行して検証します：

Kubernetesバージョン情報のHTTPリクエストを送信します：

```bash
curl -k --cacert ca.crt https://server.kubernetes.local:6443/version
```

```text
{
  "major": "1",
  "minor": "28",
  "gitVersion": "v1.28.3",
  "gitCommit": "a8a1abc25cad87333840cd7d54be2efaf31a3177",
  "gitTreeState": "clean",
  "buildDate": "2023-10-18T11:33:18Z",
  "goVersion": "go1.20.10",
  "compiler": "gc",
  "platform": "linux/arm64"
}
```

次: [Kubernetesワーカーノードのブートストラップ](09-bootstrapping-kubernetes-workers.md)
