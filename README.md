# Kubernetes The Hard Way

This workshop will walk you through setting up Kubernetes the hard way. This guide is not for people looking for a fully automated command to bring up a Kubernetes cluster. If that's you then check out [Google Container Engine](https://cloud.google.com/container-engine), or the [Getting Started Guides](http://kubernetes.io/docs/getting-started-guides/).

## Target Audience

The target audience for this workshop is someone planning to support a production Kubernetes cluster and wants to understand how everything fits together. After completing this workshop I encourage you to automate away the manual steps presented in this guide.

## Labs

* [Cloud Infrastructure Provisioning](docs/infrastructure.md)
* [Setting up a CA and TLS Cert Generation](docs/certificate-authority.md)
* [Bootstrapping an H/A etcd cluster](docs/etcd.md)
* [Bootstrapping an H/A Kubernetes Control Plane](docs/kubernetes-controller.md)
* [Bootstrapping Kubernetes Workers](docs/kubernetes-worker.md)
* [Managing the Container Network Routes](docs/network.md)
