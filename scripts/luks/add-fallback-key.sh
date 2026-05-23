#!/usr/bin/env bash
# Adds a standalone passphrase fallback keyslot to a NixOS YubiKey LUKS volume.
# Must be run on the target machine from an interactive terminal (real TTY required).
# See README.md in this directory for full context.
set -e

DEVICE="${1:-/dev/nvme0n1p2}"
STORAGE_FILE="${2:-/boot/crypt-storage/default}"

PBKDF2=$(find /nix/store -name "pbkdf2-sha512" -path "*/bin/*" 2>/dev/null | grep -v extra-utils | head -1)
YKCHALRESP=$(find /nix/store -name "ykchalresp" -path "*/bin/*" 2>/dev/null | head -1)

[ -z "$PBKDF2" ]    && { echo "pbkdf2-sha512 not found in nix store"; exit 1; }
[ -z "$YKCHALRESP" ] && { echo "ykchalresp not found in nix store"; exit 1; }

echo "pbkdf2-sha512 : $PBKDF2"
echo "ykchalresp    : $YKCHALRESP"
echo "LUKS device   : $DEVICE"
echo "Storage file  : $STORAGE_FILE"
echo

SALT=$(sudo sed -n '1p' "$STORAGE_FILE" | tr -d '\n')
ITERATIONS=$(sudo sed -n '2p' "$STORAGE_FILE" | tr -d '\n')
echo "Salt       : $SALT"
echo "Iterations : $ITERATIONS"

# Same challenge derivation as NixOS luksroot.nix
CHALLENGE=$(echo -n "$SALT" | sha512sum | cut -d' ' -f1)
echo "Challenge  : $CHALLENGE"
echo

echo "Touch your YubiKey when it flashes..."
RESPONSE=$(sudo "$YKCHALRESP" -2 -x "$CHALLENGE" 2>/dev/null)
[ -z "$RESPONSE" ] && { echo "YubiKey response failed — is it plugged in?"; exit 1; }
echo "YubiKey responded."
echo

read -s -p "Enter current YubiKey two-factor passphrase: " PASSPHRASE; echo

TMPKEY=$(mktemp /tmp/mk.XXXXXX)
trap 'sudo shred -u "$TMPKEY" 2>/dev/null; exit' EXIT INT TERM

echo -n "$PASSPHRASE" | sudo "$PBKDF2" 64 "$ITERATIONS" "$RESPONSE" > "$TMPKEY"
echo "Key derived ($(sudo wc -c < "$TMPKEY") bytes)"

sudo cryptsetup open --test-passphrase --key-file "$TMPKEY" "$DEVICE" \
  && echo "Existing key verified OK." \
  || { echo "Wrong passphrase or wrong YubiKey — aborting."; exit 1; }

echo
echo "Adding fallback keyslot (you will be prompted for the new passphrase twice)..."
sudo cryptsetup luksAddKey --key-file "$TMPKEY" "$DEVICE"

echo
echo "Done. Active keyslots:"
sudo cryptsetup luksDump "$DEVICE" | grep -E "^\s+[0-9]+: luks"
