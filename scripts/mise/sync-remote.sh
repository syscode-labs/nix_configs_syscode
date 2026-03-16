#!/usr/bin/env bash
set -euo pipefail
host="${HOST:-${1:-}}"
remote_path="${REMOTE_PATH:-/etc/nixos}"
if [ -z "$host" ]; then
  echo "usage: HOST=<host> mise run sync-remote"
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

ssh "$host" "cd '$remote_path' && git diff --name-only" > "$tmp_dir/changed_files.txt"
if [ ! -s "$tmp_dir/changed_files.txt" ]; then
  echo "no changes on $host"
  exit 0
fi

echo "changed files:"
cat "$tmp_dir/changed_files.txt"

while IFS= read -r file; do
  [ -n "$file" ] || continue
  mkdir -p "$(dirname "$file")"
  scp "$host:$remote_path/$file" "$file"
done < "$tmp_dir/changed_files.txt"

echo "sync complete; review with git diff"
