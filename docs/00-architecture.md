# Architecture

Kubernetes The Hard Way has two goals:

1. Build a small cluster by hand so every moving part is visible.
2. Show how the same ideas map to the architecture used for modern clusters.

The default lab remains intentionally small:

```text
jumpbox
server  -> kube-apiserver, kube-controller-manager, kube-scheduler, etcd
node-0  -> kubelet, kube-proxy, containerd, CNI
node-1  -> kubelet, kube-proxy, containerd, CNI
```

This layout is good for learning because there is only one place to look when debugging the control plane. It is not highly available.

## Control Plane

The control plane is the part of the cluster that stores desired state and turns that desired state into running workloads.

| Component | Responsibility |
|-----------|----------------|
| kube-apiserver | Authenticates requests, authorizes actions, validates API objects, and stores state in etcd. |
| etcd | Durable key-value store for cluster state. |
| kube-controller-manager | Runs controllers that reconcile desired state, such as Nodes, Deployments, and ServiceAccounts. |
| kube-scheduler | Assigns pending Pods to Nodes. |

In this lab, all control plane components run on `server`. In a modern resilient deployment, run three or more control-plane nodes behind a stable API endpoint.

## Worker Nodes

Each worker runs the services that make Pods real on a machine:

| Component | Responsibility |
|-----------|----------------|
| kubelet | Registers the node and manages Pod lifecycle through the container runtime. |
| containerd | Runs containers through the CRI interface. |
| runc | Creates Linux containers according to the OCI runtime spec. |
| CNI plugins | Attach Pods to the node network. |
| kube-proxy | Programs Service load-balancing rules. |

The kubelet and containerd both use the `systemd` cgroup driver in this repo. Keeping those drivers aligned matters for node stability under memory and CPU pressure.

## Trust And Identity

This repo provisions its own certificate authority and signs certificates for the Kubernetes components. The important relationships are:

| Identity | Used by |
|----------|---------|
| `admin` | Human cluster administrator. |
| `system:node:<node>` | Kubelet identity for each worker. |
| `system:kube-controller-manager` | Controller manager. |
| `system:kube-scheduler` | Scheduler. |
| `system:kube-proxy` | kube-proxy. |
| `kubernetes` | API server serving certificate. |

Authentication proves who is calling the API. Authorization decides what that caller may do. This lab uses client certificates, the Node authorizer, and RBAC.

## Networking

There are three related networks:

| Network | Default range | Purpose |
|---------|---------------|---------|
| Node network | Your machine network | SSH, API server, kubelet, etcd, and node-to-node traffic. |
| Pod network | `10.200.0.0/16` | Pod IPs allocated per worker. |
| Service network | `10.32.0.0/24` | Stable virtual IPs for Services. |

The minimal lab uses the bridge CNI plugin and manual routes so you can see exactly how Pod traffic moves between nodes. The modern track adds a real CNI option, where routing, policy, and service integration are managed by the network plugin.

## Modern Hard Way Target

After completing the minimal lab, the modern track introduces the shape used in current clusters:

```text
api.kubernetes.local
  |
  +-- load balancer or virtual IP
      |
      +-- cp-0: kube-apiserver, controller-manager, scheduler, etcd
      +-- cp-1: kube-apiserver, controller-manager, scheduler, etcd
      +-- cp-2: kube-apiserver, controller-manager, scheduler, etcd

worker-0: kubelet, containerd, CNI, kube-proxy or eBPF service handling
worker-1: kubelet, containerd, CNI, kube-proxy or eBPF service handling
worker-2: kubelet, containerd, CNI, kube-proxy or eBPF service handling
```

For stronger isolation, etcd can be moved to dedicated nodes:

```text
etcd-0, etcd-1, etcd-2
cp-0, cp-1, cp-2
worker-0, worker-1, worker-2
```

The rest of the tutorial starts with the minimal path, then adds modern networking, DNS, security, backup, upgrade, and troubleshooting practices.

Next: [Prerequisites](01-prerequisites.md)
