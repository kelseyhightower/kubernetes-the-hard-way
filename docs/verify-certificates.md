# Verify Certificates in Master-1/2 & Worker-1

This script intends to assist the verification of certificates for each Kubernetes component as part of building the cluster. The execution of the script is straight forward as soon as you have completed the Lab steps up to [Bootstrapping the Kubernetes Worker Nodes](./09-bootstrapping-kubernetes-workers.md). The script is named as `cert_verify.sh` and it is available at `/home/vagrant` directory of master-1 , master-2 and worker-1 nodes.

It is important that the script execution needs to be done by following commands after logging into the respective virtual machines [ whether it is master-1 / master-2 / worker-1 ] via SSH.

```bash
cd /home/vagrant
bash cert_verify.sh
```

Following are the successful output of script execution under different nodes,

1. VM: Master-1

    ![Master-1-Cert-Verification](./images/master-1-cert.png)

2. VM: Master-2

    ![Master-2-Cert-Verification](./images/master-2-cert.png)

3. VM: Worker-1

    ![Worker-1-Cert-Verification](./images/worker-1-cert.png)
