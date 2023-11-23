> This tutorial is a modified version of the original developed by [Kelsey Hightower](https://github.com/kelseyhightower/kubernetes-the-hard-way).

# Kubernetes The Hard Way On VirtualBox

**IMPORTANT** This currently does not work on Apple M1/M2. Oracle are yet to release a compatible version for these systems.

This tutorial walks you through setting up Kubernetes the hard way on a local machine using VirtualBox.
This guide is not for people looking for a fully automated command to bring up a Kubernetes cluster.
If that's you then check out [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine), or the [Getting Started Guides](http://kubernetes.io/docs/getting-started-guides/).

Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster.

This tutorial is a modified version of the original developed by [Kelsey Hightower](https://github.com/kelseyhightower/kubernetes-the-hard-way).
While the original one uses GCP as the platform to deploy kubernetes,  we use VirtualBox and Vagrant to deploy a cluster on a local machine. If you prefer the cloud version, refer to the original one [here](https://github.com/kelseyhightower/kubernetes-the-hard-way)

> The results of this tutorial should *not* be viewed as production ready, and may receive limited support from the community, but don't let that stop you from learning!<br/>Note that we are only building 2 masters here instead of the recommended 3 that `etcd` requires to maintain quorum. This is to save on resources, and simply to show how to load balance across more than one master.

Please note that with this particular challenge, it is all about the minute detail. If you miss one tiny step anywhere along the way, it's going to break!

Note also that in developing this lab, it has been tested *many many* times! Once you have the VMs up and you start to build the cluster, if at any point something isn't working it is 99.9999% likely to be because you missed something, not a bug in the lab!

Always run the `cert_verify.sh` script at the places it suggests, and always ensure you are on the correct node when you do stuff. If `cert_verify.sh` shows anything in red, then you have made an error in a previous step. For the master node checks, run the check on `master-1` and on `master-2`

## Target Audience

The target audience for this tutorial is someone planning to support a production Kubernetes cluster and wants to understand how everything fits together.

## Cluster Details

Kubernetes The Hard Way guides you through bootstrapping a highly available Kubernetes cluster with end-to-end encryption between components and RBAC authentication.

* [Kubernetes](https://github.com/kubernetes/kubernetes) Latest version
* [Container Runtime](https://github.com/containerd/containerd) Latest version
* [Weave Networking](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/)
* [etcd](https://github.com/coreos/etcd) v3.5.9
* [CoreDNS](https://github.com/coredns/coredns) v1.9.4

### Node configuration

We will be building the following:

* Two control plane nodes (`master-1` and `master-2`) running the control plane components as operating system services.
* Two worker nodes (`worker-1` and `worker-2`)
* One loadbalancer VM running [HAProxy](https://www.haproxy.org/) to balance requests between the two API servers.

## Labs

* [Prerequisites](docs/01-prerequisites.md)
* [Provisioning Compute Resources](docs/02-compute-resources.md)
* [Installing the Client Tools](docs/03-client-tools.md)
* [Provisioning the CA and Generating TLS Certificates](docs/04-certificate-authority.md)
* [Generating Kubernetes Configuration Files for Authentication](docs/05-kubernetes-configuration-files.md)
* [Generating the Data Encryption Config and Key](docs/06-data-encryption-keys.md)
* [Bootstrapping the etcd Cluster](docs/07-bootstrapping-etcd.md)
* [Bootstrapping the Kubernetes Control Plane](docs/08-bootstrapping-kubernetes-controllers.md)
* [Installing CRI on Worker Nodes](docs/09-install-cri-workers.md)
* [Bootstrapping the Kubernetes Worker Nodes](docs/10-bootstrapping-kubernetes-workers.md)
* [TLS Bootstrapping the Kubernetes Worker Nodes](docs/11-tls-bootstrapping-kubernetes-workers.md)
* [Configuring kubectl for Remote Access](docs/12-configuring-kubectl.md)
* [Deploy Weave - Pod Networking Solution](docs/13-configure-pod-networking.md)
* [Kube API Server to Kubelet Configuration](docs/14-kube-apiserver-to-kubelet.md)
* [Deploying the DNS Cluster Add-on](docs/15-dns-addon.md)
* [Smoke Test](docs/16-smoke-test.md)
* [E2E Test](docs/17-e2e-tests.md)
* [Extra - Certificate Verification](docs/verify-certificates.md)
