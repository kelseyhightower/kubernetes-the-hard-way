# Prerequisites

## Oracle Cloud Infrastructure

This tutorial leverages [OCI](https://www.oracle.com/cloud/) to streamline provisioning of the compute infrastructure required to bootstrap a Kubernetes cluster from the ground up. [Sign up](https://www.oracle.com/cloud/free/) for $300 in free credits.

[Estimated cost](https://www.oracle.com/cloud/cost-estimator.html) to run this tutorial: $0.38 per hour ($9.23 per day).

> The compute resources required for this tutorial exceed the OCI free tier.

## OCI CLI

### Install the OCI SDK

Follow the OCI CLI [documentation](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) to install and configure the `oci` command line utility.

Verify the OCI CLI version is 2.17.0 or higher:

```
oci --version
```

### Capture OCIDs and Generate Required Keys 

Follow the documentation [here](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm) to fetch your tenancy and user OCIDs and generate an RSA key pair, which are necessary to use the OCI CLI. 

### Create OCI Config File

Follow the documentation [here](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/sdkconfig.htm) to create an OCI config file `~/.oci/config`.  Here's an example of what it will look like:

```
[DEFAULT]
user=ocid1.user.oc1..<unique_ID>
fingerprint=<your_fingerprint>
key_file=~/.oci/oci_api_key.pem
tenancy=ocid1.tenancy.oc1..<unique_ID>
region=us-ashburn-1
```

### Set a Default Region

The above example uses "us-ashburn-1" as the region, but you can replace this with any available region.  For best
performance running the commands from this tutorial, pick a region close to your physical location.  To list 
the available regions:

```
oci iam region list
```

### Create a Compartment

Create yourself an OCI compartment, within which we'll create all the resources in this tutorial.  In the 
following command, you will need to fill in your tenancy OCID and your OCI [Home Region](https://docs.oracle.com/en-us/iaas/Content/Identity/Tasks/managingregions.htm#The).
Your Home Region will be indicated to you when you first create your tenancy.  You can also determine it
like [this](https://docs.oracle.com/en-us/iaas/Content/GSG/Reference/faq.htm#How).

```
oci iam compartment create --name kubernetes-the-hard-way --description "Kubernetes the Hard Way" \
  --compartment-id <tenancy_ocid> --region <home_region>
```

### Set this Compartment as the Default

Note the compartment `id` from the output of the above command, and create a file `~/.oci/oci_cli_rc` with 
the following content:

```
[DEFAULT]
compartment-id=<compartment_id>
```

From this point on, all `oci` commands we run will target the above compartment.

## Running Commands in Parallel with tmux

[tmux](https://github.com/tmux/tmux/wiki) can be used to run commands on multiple compute instances at the same time. Labs in this tutorial may require running the same commands across multiple compute instances, in those cases consider using tmux and splitting a window into multiple panes with synchronize-panes enabled to speed up the provisioning process.

> The use of tmux is optional and not required to complete this tutorial.

![tmux screenshot](images/tmux-screenshot.png)

> Enable synchronize-panes by pressing `ctrl+b` followed by `shift+:`. Next type `set synchronize-panes on` at the prompt. To disable synchronization: `set synchronize-panes off`.

Next: [Installing the Client Tools](02-client-tools.md)
