# Kubernetes The Hard Way

This tutorial will walk you through setting up Kubernetes the hard way. This guide is not for people looking for a fully automated command to bring up a Kubernetes cluster. If that's you then check out [Google Container Engine](https://cloud.google.com/container-engine), or the [Getting Started Guides](http://kubernetes.io/docs/getting-started-guides/).

## Target Audience

The target audience for this tutorial is someone planning to support a production Kubernetes cluster and wants to understand how everything fits together. After completing this tutorial I encourage you to automate away the manual steps presented in this guide.

## Cluster Details

* Kubernetes 1.3.0
* Docker 1.11.2
* [CNI Based Networking](https://github.com/containernetworking/cni)
* Secure communication between all components (etcd, control plane, workers)
* Default Service Account and Secrets 


### What's Missing

The resulting cluster will be missing the following items:

* [Cluster add-ons](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons)
* [Logging](http://kubernetes.io/docs/user-guide/logging)

## Labs

* [Cloud Infrastructure Provisioning](docs/infrastructure.md)
* [Setting up a CA and TLS Cert Generation](docs/certificate-authority.md)
* [Bootstrapping an H/A etcd cluster](docs/etcd.md)
* [Bootstrapping an H/A Kubernetes Control Plane](docs/kubernetes-controller.md)
* [Bootstrapping Kubernetes Workers](docs/kubernetes-worker.md)
* [Configuring the Kubernetes Client - Remote Access](docs/kubectl.md)
* [Managing the Container Network Routes](docs/network.md)
