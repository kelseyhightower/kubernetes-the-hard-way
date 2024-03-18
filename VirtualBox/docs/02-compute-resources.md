# Provisioning Compute Resources

Note: You must have VirtualBox and Vagrant configured at this point.

Download this github repository and cd into the vagrant folder:

```bash
git clone https://github.com/mmumshad/kubernetes-the-hard-way.git
```

CD into vagrant directory:

```bash
cd kubernetes-the-hard-way/vagrant
```

The `Vagrantfile` is configured to assume you have at least an 8 core CPU which most modern core i5, i7 and i9 do, and at least 16GB RAM. You can tune these values especially if you have *less* than this by editing the `Vagrantfile` before the next step below and adjusting the values for `RAM_SIZE` and `CPU_CORES` accordingly. It is not recommended to change these unless you know what you are doing as it may result in crashes and will make the lab harder to support.

This will not work if you have less than 8GB of RAM.

Run Vagrant up:

```bash
vagrant up
```


This does the below:

- Deploys 5 VMs - 2 controlplane, 2 worker and 1 loadbalancer with the name 'kubernetes-ha-* '
    > This is the default settings. This can be changed at the top of the Vagrant file.
    > If you choose to change these settings, please also update `vagrant/ubuntu/vagrant/setup-hosts.sh`
    > to add the additional hosts to the `/etc/hosts` default before running `vagrant up`.

- Set's IP addresses in the range `192.168.56.x`

    | VM            |  VM Name               | Purpose       | IP            | Forwarded Port   | RAM  |
    | ------------  | ---------------------- |:-------------:| -------------:| ----------------:|-----:|
    | controlplane01      | kubernetes-ha-controlplane01 | Master        | 192.168.56.11 |     2711         | 2048 |
    | controlplane02      | kubernetes-ha-controlplane02 | Master        | 192.168.56.12 |     2712         | 1024 |
    | node01      | kubernetes-ha-node01 | Worker        | 192.168.56.21 |     2721         | 512  |
    | node02      | kubernetes-ha-node02 | Worker        | 192.168.56.22 |     2722         | 1024 |
    | loadbalancer  | kubernetes-ha-lb       | LoadBalancer  | 192.168.56.30 |     2730         | 1024 |

    > These are the default settings. These can be changed in the Vagrant file

- Add's a DNS entry to each of the nodes to access internet
    > DNS: 8.8.8.8

- Sets required kernel settings for kubernetes networking to function correctly.

See [Vagrant page](../../vagrant/README.md) for details.

## SSH to the nodes

There are two ways to SSH into the nodes:

### 1. SSH using Vagrant

  From the directory you ran the `vagrant up` command, run `vagrant ssh \<vm\>` for example `vagrant ssh controlplane01`. This is the recommended way.
  > Note: Use VM field from the above table and not the VM name itself.

### 2. SSH Using SSH Client Tools

Use your favourite SSH terminal tool (putty).

Use the above IP addresses. Username and password-based SSH is disabled by default.

Vagrant generates a private key for each of these VMs. It is placed under the `.vagrant` folder (in the directory you ran the `vagrant up` command from) at the below path for each VM:

- **Private key path**: `.vagrant/machines/\<machine name\>/virtualbox/private_key`
- **Username/password**: `vagrant/vagrant`


## Verify Environment

- Ensure all VMs are up.
- Ensure VMs are assigned the above IP addresses.
- Ensure you can SSH into these VMs using the IP and private keys, or `vagrant ssh`.
- Ensure the VMs can ping each other.

## Troubleshooting Tips

### Failed Provisioning

If any of the VMs failed to provision, or is not configured correct, delete the VM using the command:

```bash
vagrant destroy \<vm\>
```

Then re-provision. Only the missing VMs will be re-provisioned

```bash
vagrant up
```


Sometimes the delete does not delete the folder created for the VM and throws an error similar to this:

VirtualBox error:

    VBoxManage.exe: error: Could not rename the directory 'D:\VirtualBox VMs\ubuntu-bionic-18.04-cloudimg-20190122_1552891552601_76806' to 'D:\VirtualBox VMs\kubernetes-ha-node02' to save the settings file (VERR_ALREADY_EXISTS)
    VBoxManage.exe: error: Details: code E_FAIL (0x80004005), component SessionMachine, interface IMachine, callee IUnknown
    VBoxManage.exe: error: Context: "SaveSettings()" at line 3105 of file VBoxManageModifyVM.cpp

In such cases delete the VM, then delete the VM folder and then re-provision, e.g.

```bash
vagrant destroy node02
rmdir "\<path-to-vm-folder\>\kubernetes-ha-node02
vagrant up
```

### Provisioner gets stuck

This will most likely happen at "Waiting for machine to reboot"

1. Hit `CTRL+C`
1. Kill any running `ruby` process, or Vagrant will complain.
1. Destroy the VM that got stuck: `vagrant destroy \<vm\>`
1. Re-provision. It will pick up where it left off: `vagrant up`

# Pausing the Environment

You do not need to complete the entire lab in one session. You may shut down and resume the environment as follows, if you need to power off your computer.

To shut down. This will gracefully shut down all the VMs in the reverse order to which they were started:

```bash
vagrant halt
```

To power on again:

```bash
vagrant up
```

Next: [Client tools](../../docs/03-client-tools.md)<br>
Prev: [Prerequisites](01-prerequisites.md)
