#!/usr/bin/env bash
# When VMs are deleted, IPs remain allocated in dhcpdb
# IP reclaim: https://discourse.ubuntu.com/t/is-it-possible-to-either-specify-an-ip-address-on-launch-or-reset-the-next-ip-address-to-be-used/30316

ARG=$1

set -euo pipefail

RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
BLUE="\033[1;34m"
NC="\033[0m"

echo -e "${BLUE}Checking system compatibility${NC}"

MEM_GB=$(( $(sysctl hw.memsize | cut -d ' ' -f 2) /  1073741824 ))
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/scripts
TOOLS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/../tools

CPMEM="2048M"
WNMEM="2048M"

if ! command -v multipass > /dev/null
then
    echo -e "${RED}Cannot find multipass. Did you install it as per the instructions?${NC}"
    exit 1
fi

if ! command -v jq > /dev/null
then
    echo -e "${RED}Cannot find jq. Did you install it as per the instructions?${NC}"
    exit 1
fi

if [ $MEM_GB -lt 15 ]
then
    CPMEM="768M"
    WNMEM="512M"
    echo -e "${YELLOW}System RAM is ${MEM_GB}GB. VM size is reduced."
    echo -e "It will not be possible for you to run E2E tests (final step).${NC}"
fi

specs=/tmp/vm-specs
cat <<EOF > $specs
controlplane01,2,${CPMEM},10G
controlplane02,2,${CPMEM},5G
loadbalancer,1,512M,5G
node01,2,${WNMEM},5G
node02,2,${WNMEM},5G
EOF

echo -e "${GREEN}System OK!${NC}"

# If the nodes are running, reset them
for spec in $(cat $specs)
do
    node=$(cut -d ',' -f 1 <<< $spec)
    if multipass list --format json | jq -r '.list[].name' | grep $node > /dev/null
    then
        echo -n -e $RED
        read -p "VMs are running. Delete and rebuild them (y/n)? " ans
        echo -n -e $NC
        [ "$ans" != 'y' ] && exit 1
        break
    fi
done

# Boot the nodes
for spec in $(cat $specs)
do
    node=$(cut -d ',' -f 1 <<< $spec)
    cpus=$(cut -d ',' -f 2 <<< $spec)
    ram=$(cut -d ',' -f 3 <<< $spec)
    disk=$(cut -d ',' -f 4 <<< $spec)
    if multipass list --format json | jq -r '.list[].name' | grep $(cut -d ',' -f 1 <<< $node) > /dev/null
    then
        echo -e "${YELLOW}Deleting $node${NC}"
        multipass delete $node
        multipass purge
    fi

    echo -e "${BLUE}Launching ${node}. CPU: ${cpus}, MEM: ${ram}${NC}"
    multipass launch --disk $disk --memory $ram --cpus $cpus --name $node jammy
    echo -e "${GREEN}$node booted!${NC}"
done

# Create hostfile entries
echo -e "${BLUE}Provisioning...${NC}"
hostentries=/tmp/hostentries

[ -f $hostentries ] && rm -f $hostentries

for spec in $(cat $specs)
do
    node=$(cut -d ',' -f 1 <<< $spec)
    ip=$(multipass info $node --format json | jq -r 'first( .info[] | .ipv4[0] )')
    echo "$ip $node" >> $hostentries
done

for spec in $(cat $specs)
do
    node=$(cut -d ',' -f 1 <<< $spec)
    multipass transfer $hostentries $node:/tmp/
    multipass transfer $SCRIPT_DIR/01-setup-hosts.sh $node:/tmp/
    multipass transfer $SCRIPT_DIR/cert_verify.sh $node:/home/ubuntu/
    multipass exec $node -- /tmp/01-setup-hosts.sh
done

multipass transfer $TOOLS_DIR/approve-csr.sh controlplane01:/home/ubuntu/

echo -e "${GREEN}Done!${NC}"
