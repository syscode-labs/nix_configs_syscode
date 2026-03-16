#!/usr/bin/env bash
set -euo pipefail
host="${HOST:-${1:-}}"
if [ -z "$host" ]; then
  echo "usage: HOST=<host> mise run deploy"
  exit 1
fi
exec deploy ".#$host"
