#!/usr/bin/env bash
set -euo pipefail

failed=0

while IFS=: read -r file link; do
  target="${link%%#*}"
  [ -n "${target}" ] || continue
  case "${target}" in
    http://*|https://*|mailto:*) continue ;;
    /*) continue ;;
  esac
  resolved="$(dirname "${file}")/${target}"
  if [ ! -e "${resolved}" ]; then
    echo "broken link in ${file}: ${link}"
    failed=1
  fi
done < <(rg -No '\[[^]]+\]\(([^)]+)\)' README.md docs | sed -E 's/^([^:]+):.*\]\(([^)]+)\).*$/\1:\2/')

exit "${failed}"
