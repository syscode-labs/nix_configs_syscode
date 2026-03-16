# NixOS Installation & Deployment Workflow

## Complete Hands-Off Installation

This document describes the **fully automated, zero manual steps** workflow for installing and deploying NixOS hosts.

## Prerequisites (One-Time Setup)

### 1. Initial Repository Setup

```bash
# Clone repository
git clone <repo-url> ~/nix-config
cd ~/nix-config

# Enter development environment
nix develop
```

### 2. GPG Key for Secrets

```bash
# Generate GPG key
gpg --full-generate-key

# Get fingerprint (40 characters)
gpg --list-secret-keys --keyid-format LONG --with-colons | grep fpr | cut -d: -f10

# Update .sops.yaml with your fingerprint
# Replace: REPLACE_WITH_YOUR_GPG_FINGERPRINT
```

### 3. Tailscale Authentication Key

```bash
# Visit: https://login.tailscale.com/admin/settings/keys
# - Click "Generate auth key"
# - Enable "Reusable"
# - Set expiration (or no expiration)
# - Copy the key: tskey-auth-XXXXX...

# Create secrets file
cp secrets/common/secrets.yaml.example secrets/common/secrets.yaml

# Edit and add Tailscale key
sops secrets/common/secrets.yaml
# Add under tailscale.authkey: tskey-auth-XXXXX...
```

### 4. Pre-commit Hooks

```bash
make setup
```

**That's it! Setup complete. You only do this once.**

---

## Installing a New Host

### Target Machine Requirements

- Boot NixOS installer ISO (USB, PXE, or VM)
- Note the IP address
- **That's all - no other steps on target**

### Installation Command

Run ONE command from your main laptop (bit):

```bash
just install <hostname> <category> <ip>
```

### Examples

#### Install a Laptop

```bash
# Target: Framework laptop "spark"
# Installer IP: 192.168.1.100
just install spark laptops 192.168.1.100
```

#### Install a VPS

```bash
# Target: VPS "vps-beta"
# Installer IP: 203.0.113.50
just install vps-beta vps 203.0.113.50
```

#### Install a Server

```bash
# Target: On-premises server "server-beta"
# Installer IP: 10.0.0.50
just install server-beta servers 10.0.0.50
```

#### Install an Experiment VM

```bash
# Target: Test VM "test-vm"
# Installer IP: 192.168.1.200
just install test-vm experiments 192.168.1.200
```

### What Happens (Automatically)

The command does **everything** with zero manual intervention:

1. ✅ **Generates age encryption key** (on bit, not on target)
2. ✅ **Partitions disk** (auto-detects first disk, wipes and partitions)
3. ✅ **Installs NixOS** (full system installation)
4. ✅ **Deploys age key** (transferred to target)
5. ✅ **Fetches hardware config** (auto-generated)
6. ✅ **Creates host configuration** (category-appropriate setup)
7. ✅ **Updates .sops.yaml** (adds age key automatically)
8. ✅ **Updates flake.nix** (adds host to configurations and deploy nodes)
9. ✅ **Re-encrypts secrets** (updates with new host's key)
10. ✅ **Commits changes** (git commit with descriptive message)
11. ✅ **Deploys configuration** (full system configured)

**Time: ~15 minutes**

### Result

System is now:

- ✅ Fully installed and configured
- ✅ Joined Tailscale network automatically
- ✅ All secrets decrypted and available
- ✅ Firewall configured
- ✅ SSH hardened
- ✅ Category-appropriate software installed
- ✅ Ready to use

### Access

```bash
# Via Tailscale (no IP needed)
ssh giovanni@spark

# Check status
ssh spark uname -a
ssh spark sudo tailscale status
```

---

## Categories & What They Install

### `laptops` (bit, spark, hermes)

**Purpose:** Full-featured workstations

**Installed:**
- Desktop environment (GNOME)
- Development tools (git, docker, vscode)
- Power management, Bluetooth, audio
- NetworkManager for WiFi
- Tailscale + firewall + fail2ban

**Use for:** Daily drivers, development machines

### `vps` (vps-alpha, vps-beta, ...)

**Purpose:** Hardened cloud instances

**Installed:**
- Minimal package set (vim, htop, curl, wget)
- Kernel hardening (PTI, SMAP, init_on_alloc, etc.)
- AppArmor mandatory access control
- Port knocking for SSH
- Auto-updates enabled
- Tailscale + strict firewall + fail2ban

**Use for:** Public-facing cloud servers

### `servers` (server-alpha, server-beta, ...)

**Purpose:** On-premises services

**Installed:**
- Docker for containerized services
- Prometheus node exporter
- Server utilities (rsync, ncdu, lsof)
- Tailscale + firewall + fail2ban

**Use for:** Internal services, databases, file servers

### `experiments` (test-vm, dev-box, ...)

**Purpose:** Testing and development

**Installed:**
- Full development toolchain (gcc, gdb, strace)
- Scripting languages (python, nodejs)
- Docker
- Relaxed security for quick iteration
- Tailscale + firewall

**Use for:** Testing configs, learning, temporary setups

---

## Daily Operations

### Deploy Configuration Changes

```bash
# Edit any configuration file
vim hosts/laptops/spark/configuration.nix

# Deploy to specific host
just deploy spark

# Deploy to all hosts
just deploy-all
```

### Update System Packages

```bash
# Update flake inputs (nixpkgs, home-manager, etc.)
just update

# Review changes
git diff flake.lock

# Commit
git commit -am "update: flake inputs"

# Deploy updated packages to all hosts
just deploy-all
```

### Access Hosts

```bash
# Via Tailscale name (opaque, no IP)
ssh giovanni@spark
ssh giovanni@vps-beta
ssh giovanni@server-alpha

# Check system info
ssh spark uname -a
ssh spark sudo systemctl status tailscaled
ssh spark df -h
```

### VPS Access with Port Knocking

```bash
# View knock sequence (encrypted)
sops -d secrets/vps/knock-sequences.yaml

# Knock and connect
knock -v vps-beta 7854 3219 9876
ssh giovanni@vps-beta

# Or create helper script:
# echo 'knock -v $1 7854 3219 9876 && ssh giovanni@$1' > ~/bin/knock-ssh
# chmod +x ~/bin/knock-ssh
# knock-ssh vps-beta
```

### Manage Secrets

```bash
# Edit encrypted secrets
sops secrets/common/secrets.yaml

# Add new VPS knock sequence
sops secrets/vps/knock-sequences.yaml

# After adding new host, update all secrets
sops updatekeys secrets/common/secrets.yaml
```

### Sync Changes from Remote Host

If you made changes directly on a host:

```bash
# Pull changes back to bit
make sync-remote HOST=spark

# Review changes
git diff

# Commit and push
git add .
git commit -m "sync: updates from spark"
git push

# Deploy to other hosts if needed
make deploy HOST=hermes
```

---

## Example Complete Workflow

### Scenario: Install Framework Laptop

**Target:** Framework laptop named "spark"
**Category:** laptops
**Installer IP:** 192.168.1.100

#### Step 1: Boot Installer on Target

- Insert NixOS installer USB
- Boot from USB
- Note IP address: `192.168.1.100`
- **Done with target - don't touch it again**

#### Step 2: Install from Main Laptop (bit)

```bash
# On bit
cd ~/nix-config
nix develop

# Run installation (one command)
just install spark laptops 192.168.1.100

# Confirm when prompted
# Press 'y'
```

#### Step 3: Wait (~15 minutes)

**What's happening:**
- Installing NixOS on target
- Configuring everything
- Automatically updating files
- Committing changes
- Deploying configuration

**Watch the progress in terminal**

#### Step 4: Done!

```bash
# System is ready
# Access via Tailscale
ssh giovanni@spark

# Verify
spark$ uname -a
spark$ sudo tailscale status
spark$ docker --version
spark$ code --version
```

**Everything is configured and ready to use!**

---

## Troubleshooting

### Can't Connect to Installer

**Problem:** SSH connection to installer fails

**Solution:**
```bash
# On installer console, check SSH is running
sudo systemctl status sshd

# If not started
sudo systemctl start sshd

# Set root password temporarily
sudo passwd

# Get IP address
ip addr show
```

### Installation Fails

**Problem:** Script errors during installation

**Solution:**
```bash
# Check network connectivity
ping 8.8.8.8

# Check installer logs
journalctl -xe

# Re-run installation
make install HOST=spark CATEGORY=laptops IP=192.168.1.100
```

### Tailscale Not Connected

**Problem:** Host doesn't join Tailscale

**Solution:**
```bash
# Check authkey in secrets
sops -d secrets/common/secrets.yaml | grep authkey

# Check service on host
ssh hostname sudo systemctl status tailscale-autoconnect

# Check logs
ssh hostname sudo journalctl -u tailscale-autoconnect

# Manual connection (temporary)
ssh hostname sudo tailscale up
```

### Secrets Won't Decrypt

**Problem:** SOPS errors on host

**Solution:**
```bash
# Verify age key exists
ssh hostname sudo ls -la /var/lib/sops-nix/key.txt

# Check permissions (should be 600)
ssh hostname sudo stat /var/lib/sops-nix/key.txt

# Verify .sops.yaml has host's key
grep hostname .sops.yaml

# Re-encrypt if needed
sops updatekeys secrets/common/secrets.yaml
make deploy HOST=hostname
```

### VPS Port Knocking Not Working

**Problem:** Can't SSH after knocking

**Solution:**
```bash
# Verify knock sequence
sops -d secrets/vps/knock-sequences.yaml

# Try knocking with verbose output
knock -v vps-hostname 7854 3219 9876

# Check knockd on VPS (if you can access via Tailscale)
ssh vps-hostname sudo systemctl status knockd
ssh vps-hostname sudo journalctl -u knockd

# Check firewall rules
ssh vps-hostname sudo iptables -L INPUT -v -n
```

---

## Advanced Scenarios

### Installing Multiple Hosts

```bash
# Install all laptops in sequence
just install bit laptops 192.168.1.90
# wait...
just install spark laptops 192.168.1.100
# wait...
just install hermes laptops 192.168.1.110

# Or loop through them
for host in bit:192.168.1.90 spark:192.168.1.100 hermes:192.168.1.110; do
  IFS=: read name ip <<< "$host"
  just install $name laptops $ip
done
```

### Custom Disk Layouts

For custom partitioning, modify the justfile temporarily:

```bash
# Edit partition commands in justfile
vim justfile

# Look for the "install" recipe partition section and customize
# Then run installation as normal
```

### Using Different SSH Keys

```bash
# Justfile auto-detects:
# - ~/.ssh/id_ed25519.pub (preferred)
# - ~/.ssh/id_rsa.pub (fallback)

# To use different key, temporarily copy:
cp ~/.ssh/other_key.pub ~/.ssh/id_ed25519.pub
just install spark laptops 192.168.1.100
# restore original after
```

---

## Summary

**Installing a new NixOS host is now a single command:**

```bash
just install <hostname> <category> <ip>
```

**No manual steps. No editing files. No SSH'ing to target.**

**Just boot the installer, run the command, wait 15 minutes, and your system is ready.**

**That's it. Truly hands-off.**

## Command Reference

See `docs/JUSTFILE_COMMANDS.md` for complete command reference.
