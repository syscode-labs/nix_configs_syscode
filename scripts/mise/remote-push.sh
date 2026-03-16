#!/usr/bin/env bash
set -euo pipefail
host="${HOST:-${1:-}}"
branch="${BRANCH:-${2:-main}}"
remote_path="${REMOTE_PATH:-/etc/nixos}"
if [ -z "$host" ]; then
  echo "usage: HOST=<host> [BRANCH=main] mise run remote-push"
  exit 1
fi

ssh -A "$host" bash -s <<EOS
set -euo pipefail
cd "$remote_path"
if [[ -z \\$(git status --porcelain) ]]; then
  echo "no changes to commit on $host"
  exit 0
fi
git add .
git commit -m "chore: update from $host [\\$(date +%Y-%m-%d)]"
git push origin "$branch"
EOS
