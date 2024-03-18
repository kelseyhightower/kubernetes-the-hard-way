# Run End-to-End Tests

Optional Lab.

Observations by Alistair (KodeKloud):

Depending on your computer, you may have varying success with these. I have found them to run much more smoothly on a 12 core Intel(R) Core(TM) i7-7800X Desktop Processor (circa 2017), than on a 20 core Intel(R) Core(TM) i7-12700H Laptop processor (circa 2022) - both machines having 32GB RAM and both machines running the same version of VirtualBox. On the latter, it tends to destabilize the cluster resulting in timeouts in the tests. This *may* be a processor issue in that laptop processors are not really designed to take the kind of abuse that'll be thrown by the tests at a kube cluster that really should be run on a Server processor. Laptop processors do odd things for power conservation like constantly varying the clock speed and mixing "performance" and "efficiency" cores, even when the laptop is plugged in, and this could be causing synchronization issues with the goroutines running in the kube components. If anyone has a definitive explanation for this, please do post in the Kubernetes section of the [Community Forum](https://kodekloud.com/community/c/kubernetes/6).


Test suite should be installed to and run from `controlplane01`

## Install latest Go

```bash
GO_VERSION=$(curl -s 'https://go.dev/VERSION?m=text' | head -1)
wget "https://dl.google.com/go/${GO_VERSION}.linux-${ARCH}.tar.gz"

sudo tar -C /usr/local -xzf ${GO_VERSION}.linux-${ARCH}.tar.gz

sudo ln -s /usr/local/go/bin/go /usr/local/bin/go
sudo ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

source <(go env)
export PATH=$PATH:$GOPATH/bin
```

## Install kubetest2

Here we pull the kubetest2 code, and the Google Cloud CLI which kubetest uses to pull the test packages for our version of the cluster. Kubetest will download and then compile, which takes a few minutes.


```bash
go install sigs.k8s.io/kubetest2/...@latest
sudo snap install google-cloud-cli --classic
```

## Run test

Here we set up a couple of environment variables to supply arguments to the test package - the version of our cluster and the number of CPUs on `controlplane01` to aid with test parallelization.

Then we invoke the test package

```bash
KUBE_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
NUM_CPU=$(cat /proc/cpuinfo | grep '^processor' | wc -l)

cd ~
kubetest2 noop --kubeconfig ${PWD}/.kube/config --test=ginkgo -- \
  --focus-regex='\[Conformance\]' --test-package-version $KUBE_VERSION --parallel $NUM_CPU
```

While this is running, you can open an additional session on `controlplane01` from your workstation and watch the activity in the cluster -

```
watch kubectl get all -A
```

Further observations by Alistair (KodeKloud):

This could take between an hour and several hours to run depending on your system. The number of tests run and passed will be displayed at the end. Expect some failures!

I am not able to say exactly why the failed tests fail over and above the assumptions above. It would take days to go though the truly enormous test code base to determine why the tests that fail do so.

Prev: [Smoke Test](./16-smoke-test.md)