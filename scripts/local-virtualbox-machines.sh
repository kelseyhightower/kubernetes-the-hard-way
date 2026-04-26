#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
192.168.56.11 server.kubernetes.local server
192.168.56.12 node-0.kubernetes.local node-0 10.200.0.0/24
192.168.56.13 node-1.kubernetes.local node-1 10.200.1.0/24
EOF
