# LUKS Scripts

Scripts for managing LUKS full-disk encryption on NixOS hosts that use YubiKey unlock.

## Background

Hosts like **titan** use LUKS2 with YubiKey HMAC-SHA1 challenge-response (`twoFactor = true`).
The key stored in keyslot 0 is derived as:

```
challenge  = SHA-512(salt)                          # salt from /boot/crypt-storage/default
response   = YubiKey HMAC-SHA1(slot 2, challenge)
luks_key   = PBKDF2-SHA512(passphrase, response, iterations, 64 bytes)
```

Because the passphrase alone cannot unlock the volume (the YubiKey response is required),
a second keyslot with a standalone passphrase is strongly recommended as a fallback for
recovery when the YubiKey is unavailable.

---

## add-fallback-key.sh

Adds a standalone passphrase fallback to keyslot 1 on a YubiKey-protected LUKS volume.

### Requirements

- Run **directly on the target machine** from a real interactive terminal (TTY required)
- YubiKey must be plugged in
- Must be run while the LUKS volume is already open (i.e. system is booted)

### Usage

```bash
# Default: /dev/nvme0n1p2 with salt from /boot/crypt-storage/default
bash scripts/luks/add-fallback-key.sh

# Override device and storage file
bash scripts/luks/add-fallback-key.sh /dev/sda2 /boot/crypt-storage/default
```

Or from a remote machine:

```bash
ssh -t giovanni@titan 'bash /path/to/add-fallback-key.sh'
```

### What it does

1. Reads the salt and iteration count from the boot partition (`/boot/crypt-storage/default`)
2. Computes the YubiKey challenge (`SHA-512(salt)`)
3. Gets the YubiKey response (requires physical touch)
4. Derives the existing LUKS key using `pbkdf2-sha512` (the exact NixOS initrd binary)
5. Verifies the derived key actually opens the device before proceeding
6. Prompts for the new fallback passphrase (twice) and adds it as keyslot 1
7. Shreds the temporary key file on exit (including on error/interrupt)

### Verifying keyslots after running

```bash
sudo cryptsetup luksDump /dev/nvme0n1p2 | grep -E "^\s+[0-9]+: luks"
# Expected output:
#   0: luks2   ← YubiKey-derived key
#   1: luks2   ← standalone fallback passphrase
```

### Testing the fallback

To confirm the fallback passphrase works without rebooting:

```bash
sudo cryptsetup open --test-passphrase /dev/nvme0n1p2
# Enter fallback passphrase when prompted
# "Key slot 1 unlocked." confirms success
```
