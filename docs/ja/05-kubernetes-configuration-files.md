# 認証のためのKubernetes構成ファイルの生成

このラボでは、KubernetesクライアントがKubernetes APIサーバーを見つけて認証できるようにする[Kubernetes構成ファイル](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/)、別名kubeconfigを生成します。

## クライアント認証構成

このセクションでは、`kubelet`および`admin`ユーザーのためのkubeconfigファイルを生成します。

### kubeletのKubernetes構成ファイル

Kubeletのためのkubeconfigファイルを生成する際には、Kubeletのノード名に一致するクライアント証明書を使用する必要があります。これにより、KubeletがKubernetesの[ノード認可者](https://kubernetes.io/docs/reference/access-authn-authz/node/)によって適切に認可されることが保証されます。

> 以下のコマンドは、[TLS証明書の生成](04-certificate-authority.md)ラボで使用したディレクトリ内で実行する必要があります。

node-0ワーカーノードのためのkubeconfigファイルを生成します：

```bash
for host in node-0 node-1; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443 \
    --kubeconfig=${host}.kubeconfig

  kubectl config set-credentials system:node:${host} \
    --client-certificate=${host}.crt \
    --client-key=${host}.key \
    --embed-certs=true \
    --kubeconfig=${host}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${host} \
    --kubeconfig=${host}.kubeconfig

  kubectl config use-context default \
    --kubeconfig=${host}.kubeconfig
done
```

結果：

```text
node-0.kubeconfig
node-1.kubeconfig
```

### kube-proxyのKubernetes構成ファイル

`kube-proxy`サービスのためのkubeconfigファイルを生成します：

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.crt \
    --client-key=kube-proxy.key \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default \
    --kubeconfig=kube-proxy.kubeconfig
}
```

結果：

```text
kube-proxy.kubeconfig
```

### kube-controller-managerのKubernetes構成ファイル

`kube-controller-manager`サービスのためのkubeconfigファイルを生成します：

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.crt \
    --client-key=kube-controller-manager.key \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default \
    --kubeconfig=kube-controller-manager.kubeconfig
}
```

結果：

```text
kube-controller-manager.kubeconfig
```

### kube-schedulerのKubernetes構成ファイル

`kube-scheduler`サービスのためのkubeconfigファイルを生成します：

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://server.kubernetes.local:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.crt \
    --client-key=kube-scheduler.key \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default \
    --kubeconfig=kube-scheduler.kubeconfig
}
```

結果：

```text
kube-scheduler.kubeconfig
```

### adminのKubernetes構成ファイル

`admin`ユーザーのためのkubeconfigファイルを生成します：

```bash
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default \
    --kubeconfig=admin.kubeconfig
}
```

結果：

```text
admin.kubeconfig
```

## Kubernetes構成ファイルの配布

node-0インスタンスに`kubelet`と`kube-proxy`のkubeconfigファイルをコピーします：

```bash
for host in node-0 node-1; do
  ssh root@$host "mkdir /var/lib/{kube-proxy,kubelet}"

  scp kube-proxy.kubeconfig \
    root@$host:/var/lib/kube-proxy/kubeconfig \

  scp ${host}.kubeconfig \
    root@$host:/var/lib/kubelet/kubeconfig
done
```

コントローラーインスタンスに`kube-controller-manager`と`kube-scheduler`のkubeconfigファイルをコピーします：

```bash
scp admin.kubeconfig \
  kube-controller-manager.kubeconfig \
  kube-scheduler.kubeconfig \
  root@server:~/
```

次: [データ暗号化構成とキーの生成](06-data-encryption-keys.md)
