# Kubernetes The Hard Way on KVM

This tutorial walks you through setting up Kubernetes the hard way. This guide is not for people looking for a fully automated command to bring up a Kubernetes cluster. If that's you then check out [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine), or the [Getting Started Guides](http://kubernetes.io/docs/getting-started-guides/).

Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster.

> The results of this tutorial should not be viewed as production ready, and may receive limited support from the community, but don't let that stop you from learning!


## Major Changes from Original Kubernetes the Hard Way

* Instead of GCP, KVM is used.
* HA Proxy is used as a load balancer for API Server.
* KVM host is in charge of Pod Network Routes.
* Cloud Shell in GCP is replaced by a virtual machine.
* Nodes' name and IP address starts from `1` (Note that the name of etcd nodes starts from `etcd-0`).
* The order of chapters are a little bit changed.
* The version of Ubuntu is xenial.
* (Todo) Additional information is added for CKA Exam.


## Target Audience

The target audience for this tutorial is someone planning to support a production Kubernetes cluster and wants to understand how everything fits together.

Also this tutorial assumes that the audience have some experiences of KVM (i.e. creating and deleting VMs).


## Cluster Details

Kubernetes The Hard Way guides you through bootstrapping a highly available Kubernetes cluster with end-to-end encryption between components and RBAC authentication.

* [Kubernetes](https://github.com/kubernetes/kubernetes) 1.12.0
* [containerd Container Runtime](https://github.com/containerd/containerd) 1.2.0-rc.0
* [gVisor](https://github.com/google/gvisor) 50c283b9f56bb7200938d9e207355f05f79f0d17
* [CNI Container Networking](https://github.com/containernetworking/cni) 0.6.0
* [etcd](https://github.com/coreos/etcd) v3.3.9
* [CoreDNS](https://github.com/coredns/coredns) v1.2.2


## Table of Contents

This tutorial assumes you have an KVM host or a Linux PC running KVM. While KVM host is used for basic infrastructure requirements the lessons learned in this tutorial may be applied to other platforms.

* [Prerequisites](docs/01-prerequisites.md)
* [Provisioning Compute Resources](docs/02-compute-resources.md)
* [Installing the Client Tools](docs/03-client-tools.md)
* [Provisioning the CA and Generating TLS Certificates](docs/04-certificate-authority.md)
* [Generating Kubernetes Configuration Files for Authentication](docs/05-kubernetes-configuration-files.md)
* [Generating the Data Encryption Config and Key](docs/06-data-encryption-keys.md)
* [Bootstrapping the etcd Cluster](docs/07-bootstrapping-etcd.md)
* [Bootstrapping the Kubernetes Control Plane](docs/08-bootstrapping-kubernetes-controllers.md)
* [Bootstrapping the Kubernetes Worker Nodes](docs/09-bootstrapping-kubernetes-workers.md)
* [Configuring kubectl for Remote Access](docs/10-configuring-kubectl.md)
* [Adding Pod Network Routes](docs/11-pod-network-routes.md)
* [Deploying the DNS Cluster Add-on](docs/12-dns-addon.md)
* [Smoke Test](docs/13-smoke-test.md)
* [Cleaning Up](docs/14-cleanup.md)


## References

### Kubernetes

* [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
* [Kubernetes The Hard Way - Bare Metal](https://github.com/Praqma/LearnKubernetes/blob/master/kamran/Kubernetes-The-Hard-Way-on-BareMetal.md)


### HA Proxy

* [Load Balancing with HAProxy](https://serversforhackers.com/c/load-balancing-with-haproxy)
* [How to Use HAProxy for Load Balancing](https://www.linode.com/docs/uptime/loadbalancing/how-to-use-haproxy-for-load-balancing/)
* [HAProxy TCP Reverse Proxy Setup Guide (SSL/TLS Passthrough Proxy)](https://www.ssltrust.com.au/help/setup-guides/haproxy-reverse-proxy-setup-guide)
* [TLS errors in apiserver when running with calico](https://github.com/kubernetes-incubator/bootkube/issues/960)
* [Building HAProxy so that it can use TLSv1.3](https://dnsprivacy.org/wiki/display/DP/Building+HAProxy+so+that+it+can+use+TLSv1.3)


### tmux

* [tmux Tutorial — Split Terminal Windows Easily](https://lukaszwrobel.pl/blog/tmux-tutorial-split-terminal-windows-easily/)
* [How do I equally balance tmux(1) split panes?](https://unix.stackexchange.com/questions/32986/how-do-i-equally-balance-tmux1-split-panes)


### SSH

* [Copy SSH RSA security key for multiple servers](http://www.technokain.org/copy-ssh-rsa-security-key-multiple-servers/)
