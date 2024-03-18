# Compute Resources

Because we cannot use VirtualBox and are instead using Multipass, [a script is provided](./deploy-virtual-machines.sh) to create the three VMs.

1. Run the VM deploy script from your Mac terminal application

    ```bash
    ./deploy-virtual-machines.sh
    ```

2. Verify you can connect to all VMs:

    ```bash
    multipass shell controlplane01
    ```

    You should see a command prompt like `ubuntu@controlplane01:~$`

    Type the following to return to the Mac terminal

    ```bash
    exit
    ```

    Do this for the other controlplane, both nodes and loadbalancer.

# Deleting the Virtual Machines

When you have finished with your cluster and want to reclaim the resources, perform the following steps

1. Exit from all your VM sessions
1. Run the [delete script](../delete-virtual-machines.sh) from your Mac terminal application

    ```bash
    ./delete-virtual-machines.sh
    ````

1. Clean stale DHCP leases. Multipass does not do this automatically and if you do not do it yourself you will eventually run out of IP addresses on the multipass VM network.

    1. Edit the following

        ```bash
        sudo vi /var/db/dhcpd_leases
        ```

    1. Remove all blocks that look like this, specifically those with `name` like `controlplane`, `node` or `loadbalancer`
        ```text
        {
            name=controlplane01
            ip_address=192.168.64.4
            hw_address=1,52:54:0:78:4d:ff
            identifier=1,52:54:0:78:4d:ff
            lease=0x65dc3134
        }
        ```

    1. Save the file and exit

Next: [Client tools](../../docs/03-client-tools.md)<br>
Prev: [Prerequisites](./01-prerequisites.md)
