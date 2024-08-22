# kubectlのリモートアクセス設定

このラボでは、`admin`ユーザーの資格情報に基づいて`kubectl`コマンドラインユーティリティ用のkubeconfigファイルを生成します。

> このラボのコマンドは`jumpbox`マシンから実行してください。

## Admin Kubernetes設定ファイル

各kubeconfigには接続するKubernetes APIサーバーが必要です。

前のラボで設定した`/etc/hosts`のDNSエントリに基づいて、`server.kubernetes.local`にpingできるはずです。

```bash
curl -k --cacert ca.crt \
  https://server.kubernetes.local:6443/version
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

`admin`ユーザーとして認証するためのkubeconfigファイルを生成します：

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key

  kubectl config set-context kubernetes-the-hard-way \
    --cluster=kubernetes-the-hard-way \
    --user=admin

  kubectl config use-context kubernetes-the-hard-way
}
```
上記のコマンドを実行すると、`kubectl`コマンドラインツールが使用するデフォルトの場所`~/.kube/config`にkubeconfigファイルが作成されます。これにより、configを指定せずに`kubectl`コマンドを実行できるようになります。

## 検証

リモートKubernetesクラスターのバージョンを確認します：

```bash
kubectl version
```

```text
Client Version: v1.28.3
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.28.3
```

リモートKubernetesクラスターのノードをリストします：

```bash
kubectl get nodes
```

```
NAME     STATUS   ROLES    AGE   VERSION
node-0   Ready    <none>   30m   v1.28.3
node-1   Ready    <none>   35m   v1.28.3
```

次: [Pod Network Routesのプロビジョニング](11-pod-network-routes.md)
