# Podネットワークルートのプロビジョニング

ノードにスケジュールされたPodは、ノードのPod CIDR範囲からIPアドレスを受け取ります。この時点では、ネットワーク[ルート](https://cloud.google.com/compute/docs/vpc/routes)が欠如しているため、異なるノード上で実行されている他のPodと通信することはできません。

このラボでは、各ワーカーノードのPod CIDR範囲をノードの内部IPアドレスにマッピングするルートを作成します。

> Kubernetesネットワーキングモデルを実装する[他の方法](https://kubernetes.io/docs/concepts/cluster-administration/networking/#how-to-achieve-this)もあります。

## ルーティングテーブル

このセクションでは、`kubernetes-the-hard-way` VPCネットワークにルートを作成するために必要な情報を収集します。

各ワーカーインスタンスの内部IPアドレスとPod CIDR範囲を表示します：

```bash
{
  SERVER_IP=$(grep server machines.txt | cut -d " " -f 1)
  NODE_0_IP=$(grep node-0 machines.txt | cut -d " " -f 1)
  NODE_0_SUBNET=$(grep node-0 machines.txt | cut -d " " -f 4)
  NODE_1_IP=$(grep node-1 machines.txt | cut -d " " -f 1)
  NODE_1_SUBNET=$(grep node-1 machines.txt | cut -d " " -f 4)
}
```

```bash
ssh root@server <<EOF
  ip route add ${NODE_0_SUBNET} via ${NODE_0_IP}
  ip route add ${NODE_1_SUBNET} via ${NODE_1_IP}
EOF
```

```bash
ssh root@node-0 <<EOF
  ip route add ${NODE_1_SUBNET} via ${NODE_1_IP}
EOF
```

```bash
ssh root@node-1 <<EOF
  ip route add ${NODE_0_SUBNET} via ${NODE_0_IP}
EOF
```

## 検証

```bash
ssh root@server ip route
```

```text
default via XXX.XXX.XXX.XXX dev ens160
10.200.0.0/24 via XXX.XXX.XXX.XXX dev ens160
10.200.1.0/24 via XXX.XXX.XXX.XXX dev ens160
XXX.XXX.XXX.0/24 dev ens160 proto kernel scope link src XXX.XXX.XXX.XXX
```

```bash
ssh root@node-0 ip route
```

```text
default via XXX.XXX.XXX.XXX dev ens160
10.200.1.0/24 via XXX.XXX.XXX.XXX dev ens160
XXX.XXX.XXX.0/24 dev ens160 proto kernel scope link src XXX.XXX.XXX.XXX
```

```bash
ssh root@node-1 ip route
```

```text
default via XXX.XXX.XXX.XXX dev ens160
10.200.0.0/24 via XXX.XXX.XXX.XXX dev ens160
XXX.XXX.XXX.0/24 dev ens160 proto kernel scope link src XXX.XXX.XXX.XXX
```

次: [スモークテスト](12-smoke-test.md)
