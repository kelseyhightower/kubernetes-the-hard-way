# Run End-to-End Tests

## Install Go

```bash
wget https://dl.google.com/go/go1.18.linux-amd64.tar.gz

sudo tar -C /usr/local -xzf go1.18.linux-amd64.tar.gz
```

## Install kubetest

```bash
git clone --depth 1 https://github.com/kubernetes/test-infra.git
cd test-infra/kubetest
export GOPATH="$HOME/go"
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
go build
```

> Note: it will take a while to build as it has many dependencies.


## Use the version specific to your cluster

```bash
sudo apt install jq -y
```

```bash
K8S_VERSION=$(kubectl version -o json | jq -r '.serverVersion.gitVersion')
export KUBERNETES_CONFORMANCE_TEST=y
export KUBECONFIG="$HOME/.kube/config"

./kubetest --provider=skeleton --test --test_args=”--ginkgo.focus=\[Conformance\]” --extract ${K8S_VERSION} | tee test.out
```

This could take *18 hours or more*! There are several thousand tests in the suite. The number of tests run and passed will be displayed at the end. Expect some failures as it tries tests that aren't supported by our cluster, e.g. mounting persistent volumes using NFS.

Prev: [Smoke Test](16-smoke-test.md)