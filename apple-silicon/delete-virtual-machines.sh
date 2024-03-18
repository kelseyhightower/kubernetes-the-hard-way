#!/usr/bin/env bash

set -eo pipefail

specs=/tmp/vm-specs
cat <<EOF > $specs
controlplane01,2,2048M,10G
controlplane02,2,2048M,5G
loadbalancer,1,512M,5G
node01,2,2048M,5G
node02,2,2048M,5G
EOF

for spec in $(cat $specs)
do
    n=$(cut -d ',' -f 1 <<< $spec)
    multipass stop $n
    multipass delete $n
done

multipass purge

echo
echo "You should now remove all the following lines from /var/db/dhcpd_leases"
echo
cat /var/db/dhcpd_leases | egrep -A 5 -B 1 '(controlplane|node|loadbalancer)'
echo
cat <<EOF
Use the following command to do this

  sudo vi /var/db/dhcpd_leases

EOF
