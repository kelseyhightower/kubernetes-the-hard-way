# Prerequisites

## Google Cloud Platform

This tutorial leverages the [Google Cloud Platform](https://cloud.google.com/) to streamline provisioning of the compute infrastructure required to bootstrap a Kubernetes cluster from the ground up. [Sign up](https://cloud.google.com/free/) for $300 in free credits.

[Estimated cost](https://cloud.google.com/products/calculator#id=873932bc-0840-4176-b0fa-a8cfd4ca61ae) to run this tutorial: $0.23 per hour ($5.50 per day).

> The compute resources required for this tutorial exceed the Google Cloud Platform free tier.

## Google Cloud Command Line Interface (gcloud CLI)

###  Install the Google Cloud CLI

Follow the gcloud CLI [documentation](https://cloud.google.com/cli) to install and configure the `gcloud` command line utility.

Verify the Google Cloud SDK version is 440.0.0 or higher:

```
gcloud version
```

> output

```
Google Cloud SDK 440.0.0
alpha 2023.07.21
beta 2023.07.21
bq 2.0.94
bundled-python3-unix 3.9.16
core 2023.07.21
gcloud-crc32c 1.0.0
gsutil 5.25
```

### Set a Default Compute Region and Zone

This tutorial assumes a default compute region and zone have been configured.

If you are using the `gcloud` command-line tool for the first time `init` is the easiest way to do this:

```
gcloud init
```

Then be sure to authorize gcloud to access the Cloud Platform with your Google user credentials:

```
gcloud auth login
```

Next set a default compute region and zone in your local client

```
REGION='us-east1'

ZONE='us-east1-d'

gcloud config set compute/region "${REGION}"

gcloud config set compute/zone "${ZONE}"

gcloud compute project-info add-metadata \
  --metadata "google-compute-default-region=${REGION},google-compute-default-zone=${ZONE}"
```

> Use the `gcloud compute zones list` command to view additional regions and zones.

## Running Commands in Parallel with tmux

[tmux](https://tmux.github.io/) can be used to run commands on multiple compute instances at the same time. Labs in this tutorial may require running the same commands across multiple compute instances, in those cases consider using tmux and splitting a window into multiple panes with synchronize-panes enabled to speed up the provisioning process.

> The use of tmux is optional and not required to complete this tutorial.

![tmux screenshot](./images/tmux-screenshot.png)

> Enable synchronize-panes by pressing `ctrl+b` followed by `shift+:`. Next type `set synchronize-panes on` at the prompt. To disable synchronization: `set synchronize-panes off`.

Next: [Installing the Client Tools](./02-client-tools.md)
