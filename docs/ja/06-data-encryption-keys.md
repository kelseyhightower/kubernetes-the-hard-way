# データ暗号化構成とキーの生成

Kubernetesは、クラスタの状態、アプリケーションの構成、シークレットなど、さまざまなデータを保存します。Kubernetesは、クラスタデータを保存時に[暗号化](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data)（Encryption at Rest）する機能をサポートしています。

このラボでは、Kubernetesシークレットを暗号化するのに適した暗号化キーと[暗号化構成](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/#understanding-the-encryption-at-rest-configuration)を生成します。

## 暗号化キー

暗号化キーを生成します：

```bash
export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
```

## 暗号化構成ファイル

`encryption-config.yaml`暗号化構成ファイルを作成します：

```bash
envsubst < configs/encryption-config.yaml \
  > encryption-config.yaml
```

`encryption-config.yaml`暗号化構成ファイルを各コントローラーインスタンスにコピーします：

```bash
scp encryption-config.yaml root@server:~/
```

次: [etcdクラスタのブートストラップ](07-bootstrapping-etcd.md)
