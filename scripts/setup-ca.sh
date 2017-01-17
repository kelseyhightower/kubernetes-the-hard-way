#!/usr/bin/bash
set -x

if [[ -z ${NUM_CONTROLLERS} || -z ${NUM_WORKERS} ]]; then
    echo "Must set NUM_CONTROLLERS and NUM_WORKERS environment variables"
    exit 1
fi

(( NUM_CONTROLLERS-- ))
(( NUM_WORKERS-- ))

echo '{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}' > ca-config.json

echo '{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}' > ca-csr.json

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

# Verify
openssl x509 -in ca.pem -text -noout

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes \
  --format 'value(address)')

# Order is inefficient but set up to match original example
for i in $(eval echo "{0..${NUM_WORKERS}}"); do
    hosts="${hosts}\t\"worker${i}\",\n"
done

for i in $(eval echo "{0..${NUM_WORKERS}}"); do
    hosts="${hosts}\t\"ip-10-240-0-2${i}\",\n"
done

hosts="${hosts}\t\"10.32.0.1\",\n"

for i in $(eval echo "{0..${NUM_CONTROLLERS}}"); do
    hosts="${hosts}\t\"10.240.0.1${i}\",\n"
done

for i in $(eval echo "{0..${NUM_WORKERS}}"); do
    hosts="${hosts}\t\"10.240.0.2${i}\",\n"
done

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
EOF

echo -en ${hosts} | sed 's/\t/    /' >> kubernetes-csr.json

cat >> kubernetes-csr.json <<EOF
    "${KUBERNETES_PUBLIC_ADDRESS}",
    "127.0.0.1"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Cluster",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

openssl x509 -in kubernetes.pem -text -noout

for i in $(eval echo "{0..${NUM_CONTROLLERS}}"); do
    kube_hosts="${kube_hosts}controller${i} "
done

for i in $(eval echo "{0..${NUM_WORKERS}}"); do
    kube_hosts="${kube_hosts}worker${i} "
done

for host in ${kube_hosts}; do
  gcloud compute copy-files ca.pem kubernetes-key.pem kubernetes.pem ${host}:~/
done
