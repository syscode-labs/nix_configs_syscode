#!/usr/bin/env bash
set -euo pipefail
file="${FILE:-${1:-secrets/common/secrets.yaml}}"
exec sops -d "$file"
