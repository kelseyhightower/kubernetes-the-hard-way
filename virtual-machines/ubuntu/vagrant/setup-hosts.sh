#!/usr/bin/env bash
#
# Set up /etc/hosts so we can resolve all the nodes

set -e

IP_NW=$1
BUILD_MODE=$2
NUM_WORKER_NODES=$3
MASTER_IP_START=$4
NODE_IP_START=$5
INSTALL_MODE=$6

if [ "$BUILD_MODE" = "BRIDGE" ]
then
    # Determine machine IP from route table -
    # Interface that routes to default GW that isn't on the NAT network.
    sleep 5
    MY_IP="$(ip route | grep default | grep -Pv '10\.\d+\.\d+\.\d+' | awk '{ print $9 }')"

    # From this, determine the network (which for average broadband we assume is a /24)
    MY_NETWORK=$(echo $MY_IP | awk 'BEGIN {FS="."} ; { printf("%s.%s.%s", $1, $2, $3) }')

    # Create a script that will return this machine's IP to the bridge post-provisioner.
    cat <<EOF > /usr/local/bin/public-ip
#!/usr/bin/env sh
echo -n $MY_IP
EOF
    chmod +x /usr/local/bin/public-ip
else
    # Determine machine IP from route table -
    # Interface that is connected to the NAT network.
    MY_IP="$(ip route | grep "^$IP_NW" | awk '{print $NF}')"
    MY_NETWORK=$IP_NW
fi

# Remove unwanted entries
sed -e '/^.*ubuntu-jammy.*/d' -i /etc/hosts
#sed -e '/^.*ubuntu-noble.*/d' -i /etc/hosts
sed -e "/^.*${HOSTNAME}.*/d" -i /etc/hosts

# Export PRIMARY IP as an environment variable
echo "PRIMARY_IP=${MY_IP}" >> /etc/environment

[ "$BUILD_MODE" = "BRIDGE" ] && exit 0

if [ "${INSTALL_MODE}" = "KUBEADM" ]
then
    # Update /etc/hosts about other hosts (NAT mode)
    echo "${MY_NETWORK}.${MASTER_IP_START} controlplane" >> /etc/hosts
    for i in $(seq 1 $NUM_WORKER_NODES)
    do
        num=$(( $NODE_IP_START + $i ))
        echo "${MY_NETWORK}.${num} node0${i}" >> /etc/hosts
    done
fi
