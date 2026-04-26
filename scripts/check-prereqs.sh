#!/usr/bin/env bash
set -euo pipefail

commands=(
  curl
  git
  openssl
  scp
  ssh
  tar
  wget
)

missing=0
for command in "${commands[@]}"; do
  if ! command -v "${command}" >/dev/null 2>&1; then
    echo "missing: ${command}"
    missing=1
  fi
done

arch="$(dpkg --print-architecture 2>/dev/null || true)"
case "${arch}" in
  amd64|arm64)
    echo "architecture: ${arch}"
    ;;
  "")
    echo "warning: dpkg is unavailable; confirm this host is amd64 or arm64"
    ;;
  *)
    echo "unsupported architecture: ${arch}"
    missing=1
    ;;
esac

if [ ! -f "downloads-${arch}.txt" ] && [ -n "${arch}" ]; then
  echo "missing download manifest for ${arch}"
  missing=1
fi

exit "${missing}"
