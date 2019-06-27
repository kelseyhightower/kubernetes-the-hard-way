# Introduction

This repository is intended for demo-ing the manual install of kubernetes's components on both master and worker nodes.

It should be able to get you to a working single master (insecure) kubernetes setup on a set of VMs

![End goal diagram](http://www.plantuml.com/plantuml/proxy?src=https://raw.github.com/weekendesk/kubernetes-the-hard-way/VTWO-14496/end_goal.plantuml)


# prerequisites
- vagrant
- cfssl
- cfssljson

You can run the following command to check if you've missed something (don't worry, it won't install anything on your machine)
```sh
ansible-playbook kthw-playbook.yml -t check_local_prerequisites -l localhost
```


# Root Certificate Authority
Kubernetes components implement a certificates based authentication mecanism (non revoked client certficates signed with a server's key are  valid credentials).
Etcd also implements such a mecanism.

We need a root Certificate Authority to :
  * enable authentication to the kubernetes api server.
  * enable authentication to the etcd cluster.

To generate it, run 
```sh
ansible-playbook kthw-playbook.yml -t generate_the_root_ca -l localhost
```

# Infrastructure
- provision the vms the kubernetes cluster will be running on:
```sh
vagrant up
```

# CRI-compatible container runtime
- setup a CRI-compatible container runtime on these VMs
```sh
ansible-playbook kthw-playbook.yml -t install_container_runtime -l k8s_nodes
```

# Etcd cluster
- download etcd
```sh
ansible-playbook kthw-playbook.yml -t download_etcd -l etcd_peers
```

# Kubernetes Control Plane

- download kubelet, kube-proxy, apiserver, scheduler and native controllers on the master nodes
```sh
ansible-playbook kthw-playbook.yml -t download_kubernetes_control_plane -l masters
```

# Kubernetes worker nodes
- download kubelet & kube-proxy on the worker nodes
```sh
ansible-playbook kthw-playbook.yml -t download_kubernetes_worker_components -l workers
```



