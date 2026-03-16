#!/usr/bin/env bash
set -euo pipefail
nix flake update
echo "flake inputs updated; review flake.lock and commit"
