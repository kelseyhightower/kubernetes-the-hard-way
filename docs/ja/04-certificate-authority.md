# CAのプロビジョニングとTLS証明書の生成

このラボでは、opensslを使用して[PKIインフラストラクチャ](https://en.wikipedia.org/wiki/Public_key_infrastructure)をプロビジョニングし、Certificate Authorityをブートストラップし、以下のコンポーネントのためのTLS証明書を生成します：kube-apiserver、kube-controller-manager、kube-scheduler、kubelet、およびkube-proxy。このセクションのコマンドは`jumpbox`から実行する必要があります。

## Certificate Authority

このセクションでは、他のKubernetesコンポーネントのために追加のTLS証明書を生成するために使用できるCertificate Authorityをプロビジョニングします。CAの設定と`openssl`を使用した証明書の生成は、特に初めて行う場合には時間がかかることがあります。このラボを効率化するために、各Kubernetesコンポーネントの証明書を生成するために必要な詳細を定義したopenssl設定ファイル`ca.conf`を含めました。

`ca.conf`設定ファイルを確認してください：

```bash
cat ca.conf
```

このチュートリアルを完了するために`ca.conf`ファイルのすべてを理解する必要はありませんが、`openssl`と証明書管理の高レベルな設定を学ぶための出発点と考えてください。

すべてのCertificate Authorityは、プライベートキーとルート証明書から始まります。このセクションでは自己署名のCertificate Authorityを作成しますが、これはこのチュートリアルに必要なすべてであり、実際のプロダクション環境で行うべきことではありません。

CA設定ファイル、証明書、およびプライベートキーを生成します：

```bash
{
  openssl genrsa -out ca.key 4096
  openssl req -x509 -new -sha512 -noenc \
    -key ca.key -days 3653 \
    -config ca.conf \
    -out ca.crt
}
```

結果：

```txt
ca.crt ca.key
```

## クライアントとサーバーの証明書の作成

このセクションでは、各KubernetesコンポーネントとKubernetes `admin`ユーザーのためのクライアント証明書を生成します。

証明書とプライベートキーを生成します：

```bash
certs=(
  "admin" "node-0" "node-1"
  "kube-proxy" "kube-scheduler"
  "kube-controller-manager"
  "kube-api-server"
  "service-accounts"
)
```

```bash
for i in ${certs[*]}; do
  openssl genrsa -out "${i}.key" 4096

  openssl req -new -key "${i}.key" -sha256 \
    -config "ca.conf" -section ${i} \
    -out "${i}.csr"

  openssl x509 -req -days 3653 -in "${i}.csr" \
    -copy_extensions copyall \
    -sha256 -CA "ca.crt" \
    -CAkey "ca.key" \
    -CAcreateserial \
    -out "${i}.crt"
done
```

上記のコマンドを実行すると、各Kubernetesコンポーネントのプライベートキー、証明書要求、および署名されたSSL証明書が生成されます。以下のコマンドで生成されたファイルをリストできます：

```bash
ls -1 *.crt *.key *.csr
```

## クライアントとサーバーの証明書の配布

このセクションでは、各マシンに適切な証明書とプライベートキーをコピーします。Kubernetesコンポーネントが互いに認証するために使用される資格情報としてこれらの証明書を扱う必要があります。

`node-0`と`node-1`マシンに適切な証明書とプライベートキーをコピーします：

```bash
for host in node-0 node-1; do
  ssh root@$host mkdir /var/lib/kubelet/

  scp ca.crt root@$host:/var/lib/kubelet/

  scp $host.crt \
    root@$host:/var/lib/kubelet/kubelet.crt

  scp $host.key \
    root@$host:/var/lib/kubelet/kubelet.key
done
```

`server`マシンに適切な証明書とプライベートキーをコピーします：

```bash
scp \
  ca.key ca.crt \
  kube-api-server.key kube-api-server.crt \
  service-accounts.key service-accounts.crt \
  root@server:~/
```

> `kube-proxy`、`kube-controller-manager`、`kube-scheduler`、`kubelet`クライアント証明書は、次のラボで認証構成ファイルを生成するために使用されます。

次：[認証のためのKubernetes構成ファイルの生成](05-kubernetes-configuration-files.md)
