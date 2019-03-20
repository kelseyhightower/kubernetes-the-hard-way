# Run End-to-End Tests

Install Go

```
wget https://dl.google.com/go/go1.12.1.linux-amd64.tar.gz

sudo tar -C /usr/local -xzf go1.12.1.linux-amd64.tar.gz
export GOPATH="/home/vagrant/go"
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
```

## Install kubetest

```
go get -v -u k8s.io/test-infra/kubetest
```

> Note: This may take a few minutes depending on your network speed

## Extract the Version

```
kubetest --extract=v1.13.0

cd kubernetes

export KUBE_MASTER_IP="192.168.5.11:6443"

export KUBE_MASTER=master-1

kubetest --test --provider=skeleton --test_args="--ginkgo.focus=\[Conformance\]" | tee test.out

```


This could take about 1.5 to 2 hours. The number of tests run and passed will be displayed at the end.
