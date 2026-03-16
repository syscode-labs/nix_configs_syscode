#!/usr/bin/env bash
set -euo pipefail
hosts=(bit spark hermes vps-alpha server-alpha)
for host in "${hosts[@]}"; do
  echo "deploying $host"
  deploy ".#$host"
done
