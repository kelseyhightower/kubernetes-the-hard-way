# Installing the Client Tools

In this lab you will install the command line utilities required to complete this tutorial: [jq](https://stedolan.github.io/jq/download/), [cfssl](https://github.com/cloudflare/cfssl), [cfssljson](https://github.com/cloudflare/cfssl), [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl), and set up a few shell functions.

## Install jq

Install jq:

### OS X

```
curl -o jq -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64
```

```
chmod +x jq
```

```
sudo mv jq /usr/local/bin/
```

Some OS X users may experience problems using the pre-built binaries in which case [Homebrew](https://brew.sh) might be a better option:

```
brew install jq
```

### Linux

```
curl -o jq -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
```

```
chmod +x jq
```

```
sudo mv jq /usr/local/bin/
```

## Install CFSSL

The `cfssl` and `cfssljson` command line utilities will be used to provision a [PKI Infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure) and generate TLS certificates.

Download and install `cfssl` and `cfssljson`:

### OS X

```
curl -o cfssl https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/darwin/cfssl
curl -o cfssljson https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/darwin/cfssljson
```

```
chmod +x cfssl cfssljson
```

```
sudo mv cfssl cfssljson /usr/local/bin/
```

Some OS X users may experience problems using the pre-built binaries in which case [Homebrew](https://brew.sh) might be a better option:

```
brew install cfssl
```

### Linux

```
wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl \
  https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson
```

```
chmod +x cfssl cfssljson
```

```
sudo mv cfssl cfssljson /usr/local/bin/
```

### Verification

Verify `cfssl` and `cfssljson` version 1.4.1 or higher is installed:

```
cfssl version
```

> output

```
Version: 1.4.1
Runtime: go1.12.12
```

```
cfssljson --version
```
```
Version: 1.4.1
Runtime: go1.12.12
```

## Install kubectl

The `kubectl` command line utility is used to interact with the Kubernetes API Server. Download and install `kubectl` from the official release binaries:

### OS X

```
curl -o kubectl https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/darwin/amd64/kubectl
```

```
chmod +x kubectl
```

```
sudo mv kubectl /usr/local/bin/
```

### Linux

```
wget https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl
```

```
chmod +x kubectl
```

```
sudo mv kubectl /usr/local/bin/
```

### Verification

Verify `kubectl` version 1.18.6 or higher is installed:

```
kubectl version --client
```

> output

```
Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.6", GitCommit:"dff82dc0de47299ab66c83c626e08b245ab19037", GitTreeState:"clean", BuildDate:"2020-07-15T16:58:53Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}
```

## Shell Helper Functions

In your terminal, run the following to define a few shell helper functions that we'll use throughout the tutorial:

```
function oci-fetch-public-ip(){
  # Helper function to fetch and stash the public IP for the given OCI compute instance
  if [ -z "$1" ]
  then
    echo "Usage: oci-fetch-public-ip <compute_instance_name> <optional_command>"
  else
    file=.kubernetes-the-hard-way/$1/public_ip
    if [ ! -f "$file" ] || [ ! -s "$file" ];
    then
        # Fetch the public IP and stash it for quick lookup by later commands
        echo "Fetching $1 Public IP..."
        mkdir -p .kubernetes-the-hard-way/$1
        ocid=$(oci compute instance list --lifecycle-state RUNNING --display-name $1 \
          | jq -r .data[0].id)
        oci compute instance list-vnics --instance-id $ocid | jq -r '.data[0]["public-ip"]' \
          > .kubernetes-the-hard-way/$1/public_ip 
    fi      
  fi
}

function oci-ssh(){
  # Helper function to ssh into a named OCI compute instance
  if [ -z "$1" ]
  then
    echo "Usage: oci-ssh <compute_instance_name> <optional_command>"
  else
    oci-fetch-public-ip $1
    public_ip=$(cat .kubernetes-the-hard-way/$1/public_ip)   
    ssh -i kubernetes_ssh_rsa ubuntu@$public_ip $2
  fi
}

function oci-scp(){
  # Helper function to scp a set of local files to a named OCI compute instance
  if [ -z "$3" ]
  then
    echo "Usage: oci-scp <local_file_list> <compute_instance_name> <destination>"
  else
    oci-fetch-public-ip ${@: (-2):1}
    public_ip=$(cat .kubernetes-the-hard-way/${@: (-2):1}/public_ip)   
    scp -i kubernetes_ssh_rsa "${@:1:$#-2}" ubuntu@$public_ip:${@: -1}
  fi
}
```

For convenience throughout the rest of this tutorial, you can copy the above functions into your shell's profile, to avoid having to redefine them in each of the various tmux terminals we'll create.  For example, for Bash shell, copy and past the above functions into `~/.bashrc`, then refresh the profile from your current terminal session with: 

````
. ~/.bashrc
```

Next: [Provisioning Compute Resources](03-compute-resources.md)
