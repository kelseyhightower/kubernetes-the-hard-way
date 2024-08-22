# コンピュートリソースのプロビジョニング

Kubernetes には、Kubernetes コントロールプレーンとコンテナが最終的に実行されるワーカーノードをホストするための一連のマシンが必要です。このラボでは、Kubernetes クラスターをセットアップするために必要なマシンをプロビジョニングします。

## マシンデータベース

このチュートリアルでは、Kubernetes コントロールプレーンとワーカーノードをセットアップする際に使用されるさまざまなマシン属性を保存するために、マシンデータベースとして機能するテキストファイルを活用します。以下のスキーマは、マシンデータベースのエントリを表しており、1行に1つのエントリが含まれます。

```text
IPV4_ADDRESS FQDN HOSTNAME POD_SUBNET
```

各列は、マシンの IP アドレス `IPV4_ADDRESS`、完全修飾ドメイン名 `FQDN`、ホスト名 `HOSTNAME`、および IP サブネット `POD_SUBNET` に対応しています。Kubernetes は `pod` ごとに 1 つの IP アドレスを割り当て、`POD_SUBNET` はクラスター内の各マシンに割り当てられた一意の IP アドレス範囲を表します。

以下は、このチュートリアルを作成する際に使用されたものと似たサンプルマシーンデータベースの例です。IP アドレスはマスクされています。自分のマシンには、互いに到達可能で `jumpbox` からも到達可能な任意の IP アドレスを割り当てることができます。

```bash
cat machines.txt
```

```text
XXX.XXX.XXX.XXX server.kubernetes.local server
XXX.XXX.XXX.XXX node-0.kubernetes.local node-0 10.200.0.0/24
XXX.XXX.XXX.XXX node-1.kubernetes.local node-1 10.200.1.0/24
```

今度は、Kubernetes クラスターを作成するために使用する 3 台のマシンの詳細を `machines.txt` ファイルに追加してください。上記のサンプルマシーンデータベースを使用し、自分のマシンの詳細を追加してください。

## SSH アクセスの構成

SSH は、クラスター内のマシンを構成するために使用されます。`machines.txt` ファイルに記載されている各マシンに対する `root` SSH アクセスを確認してください。各ノードで `root` SSH アクセスを有効にする必要がある場合は、`sshd_config` ファイルを更新し、SSH サーバーを再起動する必要があります。

### root SSH アクセスの有効化

自分のマシンで `root` SSH アクセスが既に有効になっている場合は、このセクションをスキップできます。

デフォルトでは、新しい `debian` インストールでは `root` ユーザーの SSH アクセスが無効になっています。これは、`root` ユーザーが Linux システムの一般的なユーザーであり、インターネットに接続されているマシンで弱いパスワードが使用されている場合、自分のマシンが他人の所有物になるのは時間の問題であるため、セキュリティ上の理由で行われます。ただし、このチュートリアルの手順を簡素化するために、`root` アクセスを SSH 上で有効にすることにします。セキュリティはトレードオフであり、この場合、便利性を最優先としています。各マシンに SSH を使用してユーザー アカウントでログインし、`su` コマンドを使用して `root` ユーザーに切り替えます。

```bash
su - root
```

`/etc/ssh/sshd_config` SSH デーモン構成ファイルの `PermitRootLogin` オプションを `yes` に設定します。

```bash
sed -i \
  's/^#PermitRootLogin.*/PermitRootLogin yes/' \
  /etc/ssh/sshd_config
```

`sshd` SSH サーバーを再起動して、更新された構成ファイルを読み込むようにします。

```bash
systemctl restart sshd
```

### SSH キーの生成と配布

このセクションでは、`server`、`node-0`、`node-1` マシンでコマンドを実行するために使用される SSH キーペアを生成し、配布します。`jumpbox` マシンから以下のコマンドを実行します。

新しい SSH キーを生成します。

```bash
ssh-keygen
```

```text
秘密鍵と公開鍵のペアを生成します。
Enter file in which to save the key (/root/.ssh/id_rsa):
パスフレーズを入力してください (パスフレーズを入力しない場合は空のまま):
パスフレーズを再入力してください:
/root/.ssh/id_rsa に識別情報が保存されました。
/root/.ssh/id_rsa.pub に公開鍵が保存されました。
```

各マシンに SSH 公開鍵をコピーします。

```bash
while read IP FQDN HOST SUBNET; do
  ssh-copy-id root@${IP}
done < machines.txt
```

各キーの追加が完了したら、SSH 公開鍵アクセスが機能していることを確認します。

```bash
while read IP FQDN HOST SUBNET; do
  ssh -n root@${IP} uname -o -m
done < machines.txt
```

```text
aarch64 GNU/Linux
aarch64 GNU/Linux
aarch64 GNU/Linux
```

## ホスト名

このセクションでは、`server`、`node-0`、`node-1` マシンにホスト名を割り当てます。ホスト名は、`jumpbox` から各マシンに対してコマンドを実行する際に使用されます。ホスト名は、Kubernetes クラスター内でも重要な役割を果たします。Kubernetes クライアントが Kubernetes API サーバーに対してコマンドを発行する際、IP アドレスではなく `server` ホスト名を使用します。ホスト名は、ワーカー マシンである `node-0` と `node-1` が特定の Kubernetes クラスターに登録する際にも使用されます。

`machines.txt` ファイルに記載されている各マシンのホスト名を構成するには、`jumpbox` から以下のコマンドを実行します。

`machines.txt` ファイルに記載されている各マシンのホスト名を設定します。

```bash
while read IP FQDN HOST SUBNET; do
    CMD="sed -i 's/^127.0.0.1.*/127.0.0.1\t${FQDN} ${HOST}/' /etc/hosts"
    ssh -n root@${IP} "$CMD"
    ssh -n root@${IP} hostnamectl hostname ${HOST}
done < machines.txt
```

各マシンのホスト名が設定されていることを確認します。

```bash
while read IP FQDN HOST SUBNET; do
  ssh -n root@${IP} hostname --fqdn
done < machines.txt
```

```text
server.kubernetes.local
node-0.kubernetes.local
node-1.kubernetes.local
```

## DNS

このセクションでは、`jumpbox` のローカル `/etc/hosts` ファイルと、チュートリアルで使用する 3 台のマシンの `/etc/hosts` ファイルに追加される DNS `hosts` ファイルを生成します。これにより、各マシンがホスト名（`server`、`node-0`、`node-1`）を使用して到達可能になります。

新しい `hosts` ファイルを作成し、ヘッダーを追加してマシンを識別します。

```bash
echo "" > hosts
echo "# Kubernetes The Hard Way" >> hosts
```

`machines.txt` ファイルに記載されている各マシンに対する DNS エントリを生成し、`hosts` ファイルに追加します。

```bash
while read IP FQDN HOST SUBNET; do
    ENTRY="${IP} ${FQDN} ${HOST}"
    echo $ENTRY >> hosts
done < machines.txt
```

`hosts` ファイルの DNS エントリを確認します。

```bash
cat hosts
```

```text

# Kubernetes The Hard Way
XXX.XXX.XXX.XXX server.kubernetes.local server
XXX.XXX.XXX.XXX node-0.kubernetes.local node-0
XXX.XXX.XXX.XXX node-1.kubernetes.local node-1
```

## ローカルマシンへの DNS エントリの追加

このセクションでは、`hosts` ファイルの DNS エントリを `jumpbox` マシンのローカル `/etc/hosts` ファイルに追加します。

`hosts` の DNS エントリを `/etc/hosts` に追加します。

```bash
cat hosts >> /etc/hosts
```

`/etc/hosts` ファイルが更新されたことを確認します。

```bash
cat /etc/hosts
```

```text
127.0.0.1       localhost
127.0.1.1       jumpbox

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters



# Kubernetes The Hard Way
XXX.XXX.XXX.XXX server.kubernetes.local server
XXX.XXX.XXX.XXX node-0.kubernetes.local node-0
XXX.XXX.XXX.XXX node-1.kubernetes.local node-1
```

この時点で、`machines.txt` ファイルに記載されている各マシンに対して、ホスト名を使用して SSH できるようになっているはずです。

```bash
for host in server node-0 node-1
   do ssh root@${host} uname -o -m -n
done
```

```text
server aarch64 GNU/Linux
node-0 aarch64 GNU/Linux
node-1 aarch64 GNU/Linux
```

## リモートマシンへの DNS エントリの追加

このセクションでは、`machines.txt` テキストファイルに記載されている各マシンの `/etc/hosts` ファイルに `hosts` ファイルの DNS エントリを追加します。

`hosts` ファイルを各マシンにコピーし、`/etc/hosts` に追加します。

```bash
while read IP FQDN HOST SUBNET; do
  scp hosts root@${HOST}:~/
  ssh -n \
    root@${HOST} "cat hosts >> /etc/hosts"
done < machines.txt
```

これで、`jumpbox` マシンまたは Kubernetes クラスター内の 3 台のマシンのいずれかから、IP アドレスの代わりにホスト名（`server`、`node-0`、`node-1`）を使用してマシンに接続できるようになりました。

次へ: [CA のプロビジョニングと TLS 証明書の生成](04-certificate-authority.md)
