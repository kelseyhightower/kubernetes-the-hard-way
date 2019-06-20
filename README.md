# Introduction

This repository is intended for demo-ing the manual install of kubernetes's components on both master and worker nodes.
It should be able to get you to a working single master kubernetes setup on a set of vagrant boxes

# prerequisites
- vagrant
- the scp vagrant plugin : `vagrant plugin install vagrant-scp`
- [the GNU parallel CLI](https://www.gnu.org/software/parallel/)

# setup
- start the vms
```sh
vagrant up
```

- setup a container runtime
```sh
./scripts/run_script_on_nodes install_container_runtime
```

- download kubernetes
```sh
./scripts/run_script_on_nodes download_node_binaries
```