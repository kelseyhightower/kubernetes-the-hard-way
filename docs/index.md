# Introduction

This tutorial walks you through setting up Kubernetes the hard way. This guide is not for someone looking for a fully automated tool to bring up a Kubernetes cluster. Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster.

> The results of this tutorial should not be viewed as production ready, and may receive limited support from the community, but don't let that stop you from learning!

## Copyright

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.


## Target Audience

The target audience for this tutorial is someone who wants to understand the fundamentals of Kubernetes and how the core components fit together.

## Cluster Details

Kubernetes The Hard Way guides you through bootstrapping a basic Kubernetes cluster with all control plane components running on a single node, and two worker nodes, which is enough to learn the core concepts.

Component versions:

* [kubernetes](https://github.com/kubernetes/kubernetes) v1.28.x
* [containerd](https://github.com/containerd/containerd) v1.7.x
* [cni](https://github.com/containernetworking/cni) v1.3.x
* [etcd](https://github.com/etcd-io/etcd) v3.4.x

## Labs

This tutorial requires four (4) ARM64 based virtual or physical machines connected to the same network. While ARM64 based machines are used for the tutorial, the lessons learned can be applied to other platforms.
