#!/usr/bin/bash
set -x

if [[ -z ${NUM_CONTROLLERS} || -z ${NUM_WORKERS} || -z ${KUBERNETES_VERSION} ]]; then
    echo "Must set NUM_CONTROLLERS, NUM_WORKERS and KUBERNETES_VERSION environment variables"
    exit 1
fi

./start-infra-gcp.sh
./setup-ca.sh
./bootstrap-etcd.sh
./bootstrap-controllers.sh
./bootstrap-workers.sh
./kubectl-remote-access.sh
./create-routes.sh
./deploy-dns.sh
./smoke-test.sh
#./cleanup.sh
