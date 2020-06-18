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
git clone https://github.com/kubernetes/test-infra.git
cd test-infra/
GO111MODULE=on go install ./kubetest
```

> Note: This may take a few minutes depending on your network speed

## Use the version specific to your cluster

```
K8S_VERSION=$(kubectl version -o json | jq -r '.serverVersion.gitVersion')
export KUBERNETES_CONFORMANCE_TEST=y
export KUBECONFIG="$HOME/.kube/config"



kubetest --provider=skeleton --test --test_args=”--ginkgo.focus=\[Conformance\]” --extract ${K8S_VERSION} | tee test.out

```


This could take about 1.5 to 2 hours. The number of tests run and passed will be displayed at the end.
