# etcdクラスタのブートストラップ

Kubernetesコンポーネントはステートレスであり、クラスタの状態を[etcd](https://github.com/etcd-io/etcd)に保存します。このラボでは、3ノードのetcdクラスタをブートストラップし、高可用性と安全なリモートアクセスのために設定します。

## 前提条件

`etcd`バイナリとsystemdユニットファイルを`server`インスタンスにコピーします：

```bash
scp \
  downloads/etcd-v3.4.27-linux-arm64.tar.gz \
  units/etcd.service \
  root@server:~/
```

このラボのコマンドはすべて`server`マシン上で実行する必要があります。`ssh`コマンドを使用して`server`マシンにログインします。例：

```bash
ssh root@server
```

## etcdクラスタのブートストラップ

### etcdバイナリのインストール

`etcd`サーバーと`etcdctl`コマンドラインユーティリティを抽出してインストールします：

```bash
{
  tar -xvf etcd-v3.4.27-linux-arm64.tar.gz
  mv etcd-v3.4.27-linux-arm64/etcd* /usr/local/bin/
}
```

### etcdサーバーの設定

```bash
{
  mkdir -p /etc/etcd /var/lib/etcd
  chmod 700 /var/lib/etcd
  cp ca.crt kube-api-server.key kube-api-server.crt \
    /etc/etcd/
}
```

etcdクラスタの各メンバーには固有の名前が必要です。現在のコンピュートインスタンスのホスト名に一致する名前を設定します：

`etcd.service` systemdユニットファイルを作成します：

```bash
mv etcd.service /etc/systemd/system/
```

### etcdサーバーの起動

```bash
{
  systemctl daemon-reload
  systemctl enable etcd
  systemctl start etcd
}
```

## 検証

etcdクラスタメンバーを一覧表示します：

```bash
etcdctl member list
```

```text
6702b0a34e2cfd39, started, controller, http://127.0.0.1:2380, http://127.0.0.1:2379, false
```

次: [Kubernetesコントロールプレーンのブートストラップ](08-bootstrapping-kubernetes-controllers.md)
