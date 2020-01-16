# Prerequisites

## Amazon Web Services (AWS)

This tutorial leverages the [Amazon Web Services](https://aws.amazon.com) to streamline provisioning of the compute infrastructure required to bootstrap a Kubernetes cluster from the ground up.

> The compute resources required for this tutorial exceed the Amazon Web Services free tier.


## CloudFormation - Infrastructure as Code

In this tutorial we use [CloudFormation](https://aws.amazon.com/cloudformation/), which enables you to provision AWS resources as a code (YAML file).

As a best practice you should consider using [Nested Stacks](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-nested-stacks.html) to combine associated CloudFormation stacks together. However, in this tutorial we provision AWS resources one by one via separated CloudFormation stacks for learning purpose.

All CloudFormation templates are in [cloudformation directory](../cloudformation/) of this repository.

## AWS CLI

### Install the AWS CLI

Follow the AWS documentation [Installing the AWS CLI version 1](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv1.html) to install and configure the `aws` command line utility.

```
$ aws --version
```

### Set a default region and credentials

This tutorial assumes a default region and credentials. To configure the AWS CLI, you can follow this instruction: [Configuring the AWS CLI - AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)

```
$ aws configure
AWS Access Key ID [None]: AKIxxxxxxxxxxxxxMPLE
AWS Secret Access Key [None]: wJalrXUxxxxxxxxxxxxxxxxxxxxxxxxxxxxLEKEY
Default region name [None]: us-west-2
Default output format [None]: json
```

## Running Commands in Parallel with tmux

[tmux](https://github.com/tmux/tmux/wiki) can be used to run commands on multiple compute instances at the same time. Labs in this tutorial may require running the same commands across multiple compute instances, in those cases consider using tmux and splitting a window into multiple panes with synchronize-panes enabled to speed up the provisioning process.

> The use of tmux is optional and not required to complete this tutorial.

![tmux screenshot](images/tmux-screenshot.png)

> Enable synchronize-panes by pressing `ctrl+b` followed by `shift+:`. Next type `set synchronize-panes on` at the prompt. To disable synchronization: `set synchronize-panes off`.

Next: [Installing the Client Tools](02-client-tools.md)
