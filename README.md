# Kubernetes The Hard Way

This tutorial will walk you through setting up Kubernetes the hard way. This guide is not for people looking for a fully automated command to bring up a Kubernetes cluster. If that's you then check out [Google Container Engine](https://cloud.google.com/container-engine), or the [Getting Started Guides](http://kubernetes.io/docs/getting-started-guides/).

This tutorial is optimized for learning, which means taking the long route to help people understand each task required to bootstrap a Kubernetes cluster. This tutorial requires access to [Google Compute Engine](https://cloud.google.com/compute).

> The results of this tutorial should not be viewed as production ready, and may receive limited support from the community, but don't let that prevent you from learning!

## Target Audience

The target audience for this tutorial is someone planning to support a production Kubernetes cluster and wants to understand how everything fits together. After completing this tutorial I encourage you to automate away the manual steps presented in this guide.

## Cluster Details

* Kubernetes 1.6.0
* Docker 1.12.6
* etcd 3.1.4
* [CNI Based Networking](https://github.com/containernetworking/cni)
* Secure communication between all components (etcd, control plane, workers)
* Default Service Account and Secrets
* [RBAC authorization enabled](https://kubernetes.io/docs/admin/authorization)
* [TLS client certificate bootstrapping for kubelets](https://kubernetes.io/docs/admin/kubelet-tls-bootstrapping)
* DNS add-on

### What's Missing

The resulting cluster will be missing the following features:

* Cloud Provider Integration
* [Cluster add-ons](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons)

## Labs

This tutorial assumes you have access to [Google Cloud Platform](https://cloud.google.com) and the [Google Cloud SDK](https://cloud.google.com/sdk/)(148.0.0+). While GCP is used for basic infrastructure needs the things learned in this tutorial can be applied to every platform.

* [Cloud Infrastructure Provisioning](docs/01-infrastructure-gcp.md)
* [Setting up a CA and TLS Cert Generation](docs/02-certificate-authority.md)
* [Setting up TLS Client Bootstrap and RBAC Authentication](docs/03-auth-configs.md)
* [Bootstrapping a H/A etcd cluster](docs/04-etcd.md)
* [Bootstrapping a H/A Kubernetes Control Plane](docs/05-kubernetes-controller.md)
* [Bootstrapping Kubernetes Workers](docs/06-kubernetes-worker.md)
* [Configuring the Kubernetes Client - Remote Access](docs/07-kubectl.md)
* [Managing the Container Network Routes](docs/08-network.md)
* [Deploying the Cluster DNS Add-on](docs/09-dns-addon.md)
* [Smoke Test](docs/10-smoke-test.md)
* [Cleaning Up](docs/11-cleanup.md)
