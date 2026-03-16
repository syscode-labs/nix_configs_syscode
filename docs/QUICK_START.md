# Quick Start Guide

## Zero-Touch NixOS Installation

Install NixOS on any machine with **zero manual steps** on the target.

### Prerequisites (One Time Setup)

```bash
# 1. Clone this repo on bit (main laptop)
git clone <repo-url> ~/nix-config && cd ~/nix-config

# 2. Enter development environment
nix develop

# 3. Set up GPG for secrets
gpg --full-generate-key
# Get fingerprint
gpg --list-secret-keys --keyid-format LONG --with-colons | grep fpr | cut -d: -f10

# 4. Update .sops.yaml with your GPG fingerprint
vim .sops.yaml

# 5. Create Tailscale authkey
# Visit: https://login.tailscale.com/admin/settings/keys
# Generate reusable key

# 6. Add to secrets
cp secrets/common/secrets.yaml.example secrets/common/secrets.yaml
sops secrets/common/secrets.yaml
# Add your Tailscale authkey

# 7. Set up pre-commit
just setup
```

### Install a New Host

#### Single Command - Fully Automated

```bash
# Boot NixOS ISO on target, note IP, then run:
just install <hostname> <category> <ip>

# Examples:
just install spark laptops 192.168.1.100        # Laptop
just install vps-beta vps 203.0.113.50          # VPS
just install server-beta servers 10.0.0.50      # Server
just install test-vm experiments 192.168.1.200  # Experiment
```

**What happens automatically:**
1. ✅ Generates age encryption key
2. ✅ Partitions and formats disk
3. ✅ Installs NixOS
4. ✅ Deploys age key
5. ✅ Fetches hardware config
6. ✅ Creates host configuration
7. ✅ Updates .sops.yaml automatically
8. ✅ Updates flake.nix automatically
9. ✅ Re-encrypts all secrets
10. ✅ Commits changes to git
11. ✅ Deploys full configuration

**Wait ~15 minutes** - completely hands-off!

#### Done!

System automatically:

- ✅ Joins Tailscale network
- ✅ Configures firewall
- ✅ Decrypts all secrets
- ✅ Applies full configuration

Access via: `ssh giovanni@spark`

**See `docs/WORKFLOW.md` for complete workflow details.**

## What Gets Installed (by Category)

### Laptops (bit, spark, hermes)

- Desktop environment (GNOME)
- Development tools (git, docker, vscode)
- Power management, Bluetooth, audio
- Tailscale, firewall, fail2ban

### VPS (vps-alpha, vps-beta, ...)

- **Minimal & hardened**
- Kernel hardening, AppArmor
- Port knocking for SSH
- Auto-updates
- Tailscale, strict firewall

### Servers (server-alpha, ...)

- Docker for services
- Prometheus monitoring
- Server utilities
- Tailscale, firewall

### Experiments (test-vm, ...)

- Development toolchain
- Relaxed security
- Docker
- Quick iteration

## Daily Workflow

### Deploy Configuration Changes

```bash
# Edit configuration
vim hosts/laptops/spark/configuration.nix

# Deploy
just deploy spark

# Deploy to all
just deploy-all
```

### Update System Packages

```bash
# Update flake inputs
just update

# Commit
git add flake.lock
git commit -m "update: nixpkgs"

# Deploy to all hosts
just deploy-all
```

### Access Hosts

```bash
# Via Tailscale (no IP needed)
ssh giovanni@spark
ssh giovanni@vps-alpha

# Check status
ssh spark 'uname -a'
ssh vps-alpha 'sudo tailscale status'
```

### VPS Access (Port Knocking)

```bash
# View knock sequence
sops -d secrets/vps/knock-sequences.yaml

# Knock and connect
just knock vps-alpha

# Or manually
knock -v vps-alpha 7854 3219 9876
ssh giovanni@vps-alpha
```

### Manage Secrets

```bash
# Edit encrypted secrets
just secrets

# Edit specific file
just secrets secrets/vps/knock-sequences.yaml

# View decrypted secrets
just secrets-view secrets/common/secrets.yaml

# Update encryption keys after adding host
just secrets-update
```

## Common Tasks

### Add SSH Key to Host

```bash
# Edit host config
vim hosts/laptops/spark/configuration.nix

# Add to users.users.giovanni.openssh.authorizedKeys.keys
# Deploy
just deploy spark
```

### Change Knock Sequence (VPS)

```bash
# Edit sequence
just secrets secrets/vps/knock-sequences.yaml

# Update keys
just secrets-update

# Deploy to VPS
just deploy vps-alpha
```

### Add New User

```bash
# Create user module
vim modules/users/alice.nix

# Add to host config
vim hosts/laptops/spark/configuration.nix
# Import and configure user

# Deploy
just deploy spark
```

### Rollback

```bash
# Rollback to previous generation
just rollback spark

# List generations
just generations spark
```

## Troubleshooting

### Can't Connect to Host

```bash
# Check Tailscale status
tailscale status | grep hostname

# Ping via Tailscale
ping hostname

# Check SSH
ssh -v giovanni@hostname
```

### Installation Failed

```bash
# Check installer has network
# From installer console:
ping 8.8.8.8

# Check SSH is running
systemctl status sshd

# Re-run install command
just install hostname category ip
```

### Secrets Won't Decrypt

```bash
# Check age key exists
ssh hostname 'sudo ls -la /var/lib/sops-nix/key.txt'

# Check permissions (should be 600)
ssh hostname 'sudo stat /var/lib/sops-nix/key.txt'

# Check .sops.yaml has host's age key
cat .sops.yaml | grep hostname

# Re-encrypt secrets
sops updatekeys secrets/common/secrets.yaml
```

### Tailscale Not Connected

```bash
# Check service
ssh hostname 'sudo systemctl status tailscaled'

# Check autoconnect service
ssh hostname 'sudo systemctl status tailscale-autoconnect'

# View logs
ssh hostname 'sudo journalctl -u tailscale-autoconnect'

# Manual connect
ssh hostname 'sudo tailscale up'
```

## Tips

1. **Always test in VM first**: Practice installations on local VM before real hardware
2. **Use Tailscale names**: Never hardcode IPs, always use hostname via Tailscale
3. **Keep secrets updated**: Rotate authkeys and knock sequences regularly
4. **Commit often**: Keep git history clean with incremental changes
5. **Deploy in order**: Deploy to laptops before VPS (test configs first)
6. **Backup age keys**: Store age private keys in password manager
7. **Document customizations**: Add comments for non-standard configurations
8. **Use categories correctly**: Choose appropriate category for security needs
9. **Test before pushing**: Run `nix flake check` before committing
10. **Monitor VPS**: Check logs regularly for unauthorized access attempts

## Getting Help

- **`docs/WORKFLOW.md`**: Complete hands-off workflow
- **`docs/JUSTFILE_COMMANDS.md`**: Full command reference
- **`docs/SOPS_GPG_SETUP.md`**: Secrets management
- **`docs/STRUCTURE_OVERVIEW.md`**: Architecture explanation
- **`AGENTS.md`**: Complete reference for AI assistants

## Quick Commands

```bash
# List all commands
just --list

# Validate config
just check

# Format code
just fmt

# Install new host (fully automated)
just install <host> <category> <ip>

# Deploy
just deploy <hostname>

# Deploy to all
just deploy-all

# Edit secrets
just secrets

# Update flake inputs
just update

# Check Tailscale
just tailscale-status <hostname>

# View system info
just info <hostname>

# Rollback
just rollback <hostname>

# Clean old generations
just clean <hostname>
```
