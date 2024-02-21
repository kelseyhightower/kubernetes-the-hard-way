# Differences between original and this solution

* Platform: I use VirtualBox to setup a local cluster, the original one uses GCP.
* Nodes: 2 master and 2 worker vs 2 master and 3 worker nodes.
* Configure 1 worker node normally and the second one with TLS bootstrap.
* Node names: I use worker-1 worker-2 instead of worker-0 worker-1.
* IP Addresses: I use statically assigned IPs on private network.
* Certificate file names: I use \<name\>.crt for public certificate and \<name\>.key for private key file. Whereas original one uses \<name\>-.pem for certificate and \<name\>-key.pem for private key.
* I generate separate certificates for etcd-server instead of using kube-apiserver.
* Network: we use weavenet.
* Add E2E Tests.
