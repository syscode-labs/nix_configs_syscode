# SOPS and GPG Setup Guide

This guide explains how to set up GPG keys for SOPS secret management and configure port knocking sequences.

## Overview

We use **SOPS** (Secrets OPerationS) with **GPG** and **age** encryption for managing secrets:
- **GPG**: Your personal key for encrypting/decrypting secrets
- **age**: Per-host keys for machines to decrypt their secrets
- **sops-nix**: NixOS module that integrates SOPS with system configuration

## Initial Setup

### Video Tutorial

📹 **Watch the secrets management walkthrough (3-4 minutes):**
```bash
asciinema play docs/tutorials/03-secrets-management.cast
```

Or view the [tutorial file directly](../tutorials/03-secrets-management.cast).

This tutorial covers GPG key generation, SOPS configuration, and editing encrypted secrets with dummy data.

### 1. GPG Admin Key (Already Configured)

The admin GPG key for this repo is:

```
Fingerprint : F646910E8FC4D54FCF88190F9EC61F85872B0E70
UID         : Giovanni Ferri <giovanni@syscode.uk>
Expires     : 2027-05-23
```

This key is already referenced in `.sops.yaml`. To use it on a new workstation, import the private key from your secure backup:

```bash
gpg --import gpg-private-key.asc
gpg --edit-key giovanni@syscode.uk
# trust → 5 (ultimate) → quit
```

To regenerate or extend the key:

```bash
# Extend expiry (preserves fingerprint)
gpg --edit-key giovanni@syscode.uk
# expire → new date → save

# Push updated key to keyserver
gpg --keyserver keys.openpgp.org --send-keys F646910E8FC4D54FCF88190F9EC61F85872B0E70
```

Always use a strong passphrase when generating or importing GPG keys. Store it in your password manager.

### 2. Get Your GPG Fingerprint

```bash
# List your GPG keys
gpg --list-secret-keys --keyid-format LONG

# Copy the full 40-character fingerprint (without spaces)
gpg --list-secret-keys --keyid-format LONG --with-colons | grep fpr | cut -d: -f10
```

### 3. Update .sops.yaml

Edit `.sops.yaml` and set your fingerprint under the admin key:

```yaml
keys:
  - &admin_giovanni F646910E8FC4D54FCF88190F9EC61F85872B0E70
```

### 4. Generate Age Keys on Each Host

On each NixOS machine, generate an age key:

```bash
# SSH into the machine
ssh bit  # or spark, hermes, etc.

# Generate age key
sudo mkdir -p /var/lib/sops-nix
sudo age-keygen -o /var/lib/sops-nix/key.txt

# Get the public key
sudo age-keygen -y /var/lib/sops-nix/key.txt
# Output: age1abcdefg...xyz (copy this)

# Set proper permissions
sudo chmod 600 /var/lib/sops-nix/key.txt
sudo chown root:root /var/lib/sops-nix/key.txt
```

### 5. Update .sops.yaml with Age Keys

For each host, add its age public key to `.sops.yaml`. Current registered host keys:

```yaml
keys:
  - &titan_age age1jdmwvx9jfgyhp9xledlkhrf0nsuax47pj2982y0k2nr6d7hspssqn6sdna
  # Add new hosts below as they are provisioned
  # - &spark_age age1...
```

Add the new host's key to the relevant `creation_rules` paths (e.g. `secrets/common/*` and `secrets/laptops/*`) so sops can re-encrypt for it.

## Tailscale OAuth Setup

This repo uses a Tailscale **OAuth client** instead of a static authkey. A single OAuth client secret generates unique per-machine ephemeral keys at registration time — no rotation needed across hosts.

### Create the OAuth Client (One Time)

1. Go to <https://login.tailscale.com/admin/settings/oauth>
2. Click **Generate OAuth client**
3. Under **Scopes**, expand **Devices** and enable `auth_keys` (write)
4. Save the **Client ID** and **Client Secret**

### Store in sops secrets

```yaml
# secrets/common/secrets.yaml (before encryption)
tailscale:
  oauth_id: tskey-client-XXXXXXXXXXXXXXXX
  oauth_secret: tskey-client-XXXXXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXX
```

```bash
# Encrypt in place
sops -e -i secrets/common/secrets.yaml
```

### How it Works in NixOS

`modules/networking/tailscale.nix` reads `tailscale_oauth_secret` from sops and passes it to `services.tailscale.authKeyFile`. On first boot the machine registers itself and joins the tailnet automatically.

---

## Creating and Encrypting Secrets

### Port Knocking Sequence Setup

1. **Create the knock sequence file:**

```bash
# Copy the example
cp secrets/vps/knock-sequences.yaml.example secrets/vps/knock-sequences.yaml

# Edit the file
vim secrets/vps/knock-sequences.yaml
```

2. **Example knock sequence:**

```yaml
knockd:
  sequence:
    - 7854
    - 3219
    - 9876
```

3. **Encrypt the file:**

```bash
# Encrypt with sops
sops -e -i secrets/vps/knock-sequences.yaml

# The file is now encrypted. You can safely commit it.
```

4. **Edit encrypted secrets:**

```bash
# SOPS will decrypt, open in editor, then re-encrypt on save
sops secrets/vps/knock-sequences.yaml
```

### Common Secret Management Commands

```bash
# Encrypt a new secret file
sops -e secrets/common/my-secret.yaml > secrets/common/my-secret.enc.yaml

# Edit an encrypted file
sops secrets/common/my-secret.enc.yaml

# View encrypted file content (decrypted)
sops -d secrets/common/my-secret.enc.yaml

# Encrypt in-place
sops -e -i secrets/common/my-secret.yaml
```

## Using Secrets in NixOS Configuration

### In Module Files

```nix
{ config, pkgs, ... }:

{
  # Configure sops-nix
  sops = {
    defaultSopsFile = ../../secrets/common/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      # Define secrets to decrypt at boot
      "knockd/sequence" = {
        owner = "root";
        mode = "0400";
      };

      "user/password" = {
        neededForUsers = true;
      };
    };
  };

  # Use secret in configuration
  services.knockd.configFile = pkgs.writeText "knockd.conf" ''
    [openSSH]
    sequence = ${config.sops.placeholder."knockd/sequence"}
  '';

  # Set user password from secret
  users.users.giovanni.hashedPasswordFile = config.sops.secrets."user/password".path;
}
```

### Secret File Structure

YAML format for secrets:

```yaml
# secrets/vps/secrets.yaml
knockd:
  sequence:
    - 7000
    - 8000
    - 9000

user:
  password: $6$rounds=656000$HASHED_PASSWORD_HERE

tailscale:
  authkey: tskey-auth-XXXXXXXXXXXXX

api:
  github_token: ghp_XXXXXXXXXXXXX
```

## Port Knocking Client Usage

### From Your Laptop

Install knock client:

```bash
# NixOS
nix-shell -p knockd

# Or install permanently
environment.systemPackages = [ pkgs.knockd ];
```

### Knock and Connect

```bash
# Knock the sequence (replace with your actual sequence)
knock -v your-vps-ip 7000 8000 9000

# Then immediately SSH (port will be open for ~30 seconds)
ssh giovanni@your-vps-ip
```

### Create a Convenience Script

Create `scripts/knock-and-ssh.sh`:

```bash
#!/usr/bin/env bash
HOST="$1"
SEQUENCE="7000 8000 9000"  # Your actual sequence

knock -v "$HOST" $SEQUENCE && sleep 1 && ssh "giovanni@$HOST"
```

## Security Best Practices

1. **GPG Key Protection:**
   - Use a strong passphrase
   - Store passphrase in a password manager
   - Back up your GPG private key securely
   - Consider using a hardware security key (YubiKey)

2. **Age Keys:**
   - Generated on each host, never leave the machine
   - Stored in `/var/lib/sops-nix/` with root-only access
   - If a machine is compromised, rotate the age key

3. **Port Knocking:**
   - Use random, non-sequential ports
   - Change sequences periodically
   - Don't share sequences in plain text
   - Consider using different sequences per VPS

4. **Secret Rotation:**
   - Rotate secrets periodically
   - Update knock sequences every few months
   - Revoke old API keys/tokens

## Troubleshooting

### Can't Decrypt Secrets

```bash
# Check GPG key is available
gpg --list-secret-keys

# Check age key exists on host
sudo cat /var/lib/sops-nix/key.txt

# Verify .sops.yaml has correct keys
cat .sops.yaml
```

### SOPS Errors

```bash
# Re-encrypt with updated keys
sops updatekeys secrets/vps/knock-sequences.yaml

# Check which keys can decrypt
sops -d secrets/vps/knock-sequences.yaml
```

### Port Knocking Not Working

```bash
# Check knockd is running
sudo systemctl status knockd

# Check firewall rules
sudo iptables -L INPUT -v -n

# Test knock sequence
knock -v vps-ip 7000 8000 9000

# Check logs
sudo journalctl -u knockd -f
```

## Backup and Recovery

### Backup GPG Key

```bash
# Export private key (keep this EXTREMELY secure!)
gpg --export-secret-keys --armor your.email@example.com > gpg-private-key.asc

# Store in password manager or encrypted backup
```

### Restore GPG Key

```bash
# Import private key
gpg --import gpg-private-key.asc

# Trust the key
gpg --edit-key your.email@example.com
# Type: trust
# Choose: 5 (ultimate)
# Type: quit
```

### Regenerate Age Keys

If you lose a host's age key, regenerate it:

```bash
# On the host
sudo age-keygen -o /var/lib/sops-nix/key.txt
sudo age-keygen -y /var/lib/sops-nix/key.txt  # Get public key

# Update .sops.yaml with new public key
# Re-encrypt all secrets for that host
sops updatekeys secrets/vps/knock-sequences.yaml
```
