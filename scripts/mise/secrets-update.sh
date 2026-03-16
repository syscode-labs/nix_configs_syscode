#!/usr/bin/env bash
set -euo pipefail
while IFS= read -r file; do
  [ -n "$file" ] || continue
  echo "updating keys: $file"
  sops updatekeys "$file"
done < <(find secrets -type f \( -name '*.yaml' -o -name '*.yml' \) | sort)
