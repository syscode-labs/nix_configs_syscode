#!/usr/bin/env bash
set -euo pipefail
host="${HOST:-${1:-}}"
if [ -z "$host" ]; then
  echo "usage: HOST=<host> mise run pull-deploy"
  exit 1
fi
git pull --ff-only
deploy ".#$host"
