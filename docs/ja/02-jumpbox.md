# Jumpboxのセットアップ

このラボでは、4台のマシンのうち1台を`jumpbox`として設定します。このマシンはこのチュートリアルでコマンドを実行するために使用されます。専用のマシンを使用して一貫性を確保しますが、これらのコマンドはmacOSやLinuxを実行している個人のワークステーションを含むほぼすべてのマシンから実行することもできます。

`jumpbox`を、Kubernetesクラスターをゼロからセットアップする際のホームベースとして使用する管理マシンと考えてください。始める前に、いくつかのコマンドラインユーティリティをインストールし、Kubernetes The Hard Wayのgitリポジトリをクローンする必要があります。このリポジトリには、このチュートリアル全体でさまざまなKubernetesコンポーネントを構成するために使用される追加の設定ファイルが含まれています。

`jumpbox`にログインします：

```bash
ssh root@jumpbox
```

すべてのコマンドは`root`ユーザーとして実行されます。これは利便性のために行われており、すべてをセットアップするために必要なコマンドの数を減らすのに役立ちます。

### コマンドラインユーティリティのインストール

`root`ユーザーとして`jumpbox`マシンにログインしたので、チュートリアル全体でさまざまなタスクを実行するために使用されるコマンドラインユーティリティをインストールします。

```bash
apt-get -y install wget curl vim openssl git
```

### GitHubリポジトリの同期

次に、このチュートリアルのコピーをダウンロードします。このコピーには、ゼロからKubernetesクラスターを構築するために使用される設定ファイルとテンプレートが含まれています。`git`コマンドを使用してKubernetes The Hard Wayのgitリポジトリをクローンします：

```bash
git clone --depth 1 \
  https://github.com/kelseyhightower/kubernetes-the-hard-way.git
```

`kubernetes-the-hard-way`ディレクトリに移動します：

```bash
cd kubernetes-the-hard-way
```

これがチュートリアルの残りの部分の作業ディレクトリになります。コマンドを実行する際に迷子になった場合は、`pwd`コマンドを実行して正しいディレクトリにいることを確認してください：

```bash
pwd
```

```text
/root/kubernetes-the-hard-way
```

### バイナリのダウンロード

このセクションでは、さまざまなKubernetesコンポーネントのバイナリをダウンロードします。バイナリは`jumpbox`の`downloads`ディレクトリに保存されます。これにより、Kubernetesクラスターの各マシンに対してバイナリを複数回ダウンロードすることを避け、チュートリアルを完了するために必要なインターネット帯域幅を減らすことができます。

`kubernetes-the-hard-way`ディレクトリから`mkdir`コマンドを使用して`downloads`ディレクトリを作成します：

```bash
mkdir downloads
```

ダウンロードされるバイナリは`downloads.txt`ファイルにリストされています。`cat`コマンドを使用して確認できます：

```bash
cat downloads.txt
```

`downloads.txt`ファイルにリストされているバイナリを`wget`コマンドを使用してダウンロードします：

```bash
wget -q --show-progress \
  --https-only \
  --timestamping \
  -P downloads \
  -i downloads.txt
```

インターネット接続速度によっては、`584`メガバイトのバイナリをダウンロードするのに時間がかかる場合があります。ダウンロードが完了したら、`ls`コマンドを使用してリストできます：

```bash
ls -loh downloads
```

```text
total 584M
-rw-r--r-- 1 root  41M May  9 13:35 cni-plugins-linux-arm64-v1.3.0.tgz
-rw-r--r-- 1 root  34M Oct 26 15:21 containerd-1.7.8-linux-arm64.tar.gz
-rw-r--r-- 1 root  22M Aug 14 00:19 crictl-v1.28.0-linux-arm.tar.gz
-rw-r--r-- 1 root  15M Jul 11 02:30 etcd-v3.4.27-linux-arm64.tar.gz
-rw-r--r-- 1 root 111M Oct 18 07:34 kube-apiserver
-rw-r--r-- 1 root 107M Oct 18 07:34 kube-controller-manager
-rw-r--r-- 1 root  51M Oct 18 07:34 kube-proxy
-rw-r--r-- 1 root  52M Oct 18 07:34 kube-scheduler
-rw-r--r-- 1 root  46M Oct 18 07:34 kubectl
-rw-r--r-- 1 root 101M Oct 18 07:34 kubelet
-rw-r--r-- 1 root 9.6M Aug 10 18:57 runc.arm64
```

### kubectlのインストール

このセクションでは、公式のKubernetesクライアントコマンドラインツールである`kubectl`を`jumpbox`マシンにインストールします。`kubectl`は、後でクラスターがプロビジョニングされた後にKubernetesコントロールと対話するために使用されます。

`chmod`コマンドを使用して`kubectl`バイナリを実行可能にし、`/usr/local/bin/`ディレクトリに移動します：

```bash
{
  chmod +x downloads/kubectl
  cp downloads/kubectl /usr/local/bin/
}
```

この時点で`kubectl`がインストールされ、`kubectl`コマンドを実行して確認できます：

```bash
kubectl version --client
```

```text
Client Version: v1.28.3
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
```

この時点で、`jumpbox`はこのチュートリアルのラボを完了するために必要なすべてのコマンドラインツールとユーティリティでセットアップされています。

次: [コンピュートリソースのプロビジョニング](03-compute-resources.md)
