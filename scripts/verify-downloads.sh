#!/usr/bin/env bash
set -euo pipefail

manifest="${1:-downloads-$(dpkg --print-architecture).txt}"

if [ ! -f "${manifest}" ]; then
  echo "manifest not found: ${manifest}" >&2
  exit 1
fi

if grep -E 'rc\.|beta|alpha' "${manifest}"; then
  echo "pre-release dependency found in ${manifest}" >&2
  exit 1
fi

while IFS= read -r url; do
  [ -n "${url}" ] || continue
  case "${url}" in
    https://*) ;;
    *)
      echo "non-https url: ${url}" >&2
      exit 1
      ;;
  esac
done < "${manifest}"

echo "download manifest looks sane: ${manifest}"
