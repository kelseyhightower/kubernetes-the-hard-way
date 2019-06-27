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

# setup
- run `vagrant up` to start the vms. This will create a master node and 2 worker nodes on your host's network

- setup a container runtime on the nodes
```sh
ansible-playbook kthw-playbook.yml -t install_container_runtime -l k8s_nodes
```

- install kubelet, kube-proxy, apiserver, scheduler and native controllers on the master nodes
```sh
ansible-playbook kthw-playbook.yml -t install_kubernetes_master_components -l masters
```

- install kubelet & kube-proxy on the worker nodes
```sh
ansible-playbook kthw-playbook.yml -t install_kubernetes_worker_components -l workers
```

- install etcd on the master nodes
```sh
ansible-playbook kthw-playbook.yml -t install_etcd -l masters
```
