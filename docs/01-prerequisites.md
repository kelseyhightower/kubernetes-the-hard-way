# Prerequisites

In this lab you will review the machine requirements necessary to follow this tutorial.

## Virtual or Physical Machines

This tutorial requires four (4) virtual or physical ARM64 machines running Debian 12 (bookworm). The follow table list the four machines and thier CPU, memory, and storage requirements.

| Name    | Description            | CPU | RAM   | Storage |
|---------|------------------------|-----|-------|---------|
| jumpbox | Administration host    | 1   | 512MB | 10GB    |
| server  | Kubernetes server      | 1   | 2GB   | 20GB    |
| node-0  | Kubernetes worker node | 1   | 2GB   | 20GB    |
| node-1  | Kubernetes worker node | 1   | 2GB   | 20GB    |

How you provision the machines is up to you, the only requirement is that each machine meet the above system requirements including the machine specs and OS version. Once you have all four machine provisioned, verify the system requirements by running the `uname` command on each machine:

```bash 
uname -mov
```

After running the `uname` command you should see the following output:

```text
#1 SMP Debian 6.1.55-1 (2023-09-29) aarch64 GNU/Linux
```

You maybe surprised to see `aarch64` here, but that is the official name for the Arm Architecture 64-bit instruction set. You will often see `arm64` used by Apple, and the maintainers of the Linux kernel, when referring to support for `aarch64`. This tutorial will use `arm64` consistently throughout to avoid confusion.

Next: [setting-up-the-jumpbox](02-jumpbox.md)
