# AI Assistant Guide

This file provides guidance to AI coding assistants (Claude Code, GitHub Copilot, Cursor, etc.) when working with code in this repository.

## Overview

This is a NixOS configuration repository using flakes with **categorized hosts** for better organization and security. It manages system configurations for multiple hosts with modular, reusable components. Secrets are managed via sops-nix with GPG/age encryption. All hosts include Tailscale, hardened firewall, and port knocking for secure remote access.

**All commands use `justfile`** - run `just --list` to see available commands.

## Architecture

### Host Categories

Hosts are organized into categories with different configurations:

- **laptops/**: Full-featured workstations (bit, spark, hermes)
  - Desktop environments, development tools, Docker
  - Power management, Bluetooth, audio

- **vps/**: Minimal, hardened cloud VPS instances
  - Headless, kernel hardening, aggressive security
  - Port knocking for SSH access
  - Auto-updates, minimal package set

- **servers/**: On-premises servers
  - Docker support, monitoring (Prometheus)
  - Headless but less restrictive than VPS

- **experiments/**: Testing and development hosts
  - Relaxed security, development tools
  - Quick iteration, temporary configurations

### Flake Structure

- **flake.nix**: Defines all hosts using `mkHost` helper for DRY configuration
- Each host imports its category config (e.g., `hosts/categories/laptops.nix`)
- Category configs import base modules (common, networking, security)
- Hostnames are opaque - use Tailscale or SSH config aliases for addressing

### Module Organization

- **hosts/common/**: Shared configuration (nix settings, locale, common packages)
- **hosts/categories/**: Category-specific configurations (laptops.nix, vps.nix, servers.nix, experiments.nix)
- **hosts/{category}/{hostname}/**: Individual host configurations
- **modules/users/**: Home Manager configurations (overridable per-host)
- **modules/system/**: System-level modules (security)
- **modules/networking/**: Networking modules (tailscale, firewall, port knocking)
- **packages/**: Custom package definitions
- **overlays/**: Nixpkgs overlays

### Security Architecture

All hosts include:
- **Tailscale**: Zero-trust mesh VPN for secure access
- **Hardened firewall**: Only SSH allowed, protected by port knocking on VPS
- **Port knocking**: VPS hosts require knock sequence (encrypted in sops)
- **SSH hardening**: Key-only auth, rate limiting, fail2ban
- **SOPS**: GPG + age encryption for secrets

## Common Development Commands

**All commands use justfile.** See `docs/JUSTFILE_COMMANDS.md` for complete reference.

### Development Environment

```bash
# Enter development shell with all tools (deploy-rs, sops, knockd, etc.)
nix develop
```

### Building and Deploying

#### Local Deployment (on the machine itself)

```bash
# Build and switch to new configuration
sudo nixos-rebuild switch --flake .#bit

# Test build without switching
sudo nixos-rebuild build --flake .#spark

# Build specific host configuration
nix build .#nixosConfigurations.hermes.config.system.build.toplevel
```

#### Remote Deployment (from central laptop - bit)

```bash
# Deploy to remote machine
just deploy spark
just deploy vps-alpha

# Deploy to all hosts
just deploy-all

# Dry run to see what would change
just dry-run hermes
```

### Validation and Formatting

```bash
# Check flake for errors (validates all configurations)
just check

# Format all Nix files
just fmt

# Format check without modifying
just fmt-check
```

### Flake Management

```bash
# Update all flake inputs (nixpkgs, home-manager, etc.)
just update

# Show flake outputs
nix flake show
```

### Secrets Management

```bash
# Edit encrypted secrets
just secrets
just secrets secrets/vps/knock-sequences.yaml

# View decrypted content
just secrets-view secrets/vps/knock-sequences.yaml

# Update encryption keys for all secrets
just secrets-update
```

### Port Knocking

```bash
# Knock and connect to VPS
just knock vps-alpha

# Or manually
knock -v vps-alpha 7000 8000 9000 && ssh giovanni@vps-alpha
```

## Fully Automated Installation

This repository supports **zero-touch installation** - boot NixOS installer and deploy remotely with a single command.

### Install New Host

```bash
# Boot NixOS installer on target, note IP, then run:
just install <hostname> <category> <ip>

# Examples:
just install spark laptops 192.168.1.100        # Laptop
just install vps-beta vps 203.0.113.50          # VPS
just install server-beta servers 10.0.0.50      # Server
just install test-vm experiments 192.168.1.200  # Experiment
```

**What happens automatically:**
1. Generates age encryption key
2. Partitions and formats disk
3. Installs NixOS
4. Deploys age key
5. Fetches hardware config
6. Creates host configuration
7. Updates .sops.yaml automatically
8. Updates flake.nix automatically
9. Re-encrypts all secrets
10. Commits changes to git
11. Deploys full configuration

**Time: ~15 minutes, completely hands-off.**

See `docs/WORKFLOW.md` for complete installation workflow.

## Centralized Deployment Workflow

This repository supports centralized deployment from **bit** (main laptop) to all other machines without storing git credentials anywhere.

### Deployment Architecture

- **Central laptop (bit)**: Has the repository and SSH agent with keys
- **Remote machines**: Receive deployments via deploy-rs over Tailscale
- **Git operations**: Use SSH agent forwarding (no credentials stored on remote machines)

### Common Deployment Workflows

#### Deploy to Remote Machine

```bash
# From bit
just deploy spark
just deploy vps-alpha
```

#### Pull Latest Changes and Deploy

```bash
just pull-deploy spark
```

#### Sync Changes Made on Remote Machine

```bash
# Pull changes back to central repo
just sync-remote spark

# Then review, commit, and push
git diff
git add .
git commit -m "sync: changes from spark"
git push
```

#### Push from Remote Using Agent Forwarding

```bash
just remote-push spark main
```

### SSH Agent Forwarding

Remote machines can perform git operations using your local SSH keys:

- Requires `ForwardAgent yes` in SSH config
- SSH agent must be running on bit: `eval "$(ssh-agent -s)" && ssh-add`
- Test with: `ssh -A spark 'ssh-add -l'`

### Adding a New Remote Machine

1. Boot NixOS installer on target machine
2. Run: `just install <hostname> <category> <ip>`
3. Everything else is automatic (config creation, secrets, deployment)

See `docs/WORKFLOW.md` for detailed workflow guide.

## Key Patterns

### Adding a New Host (Manual Method)

If not using automated installation:

1. Create directory: `mkdir -p hosts/{category}/{hostname}`
2. Create `configuration.nix` and `hardware-configuration.nix`
3. Add to `flake.nix`:

```nix
nixosConfigurations.newhostname = mkHost {
  hostname = "newhostname";
  category = "laptops"; # or vps, servers, experiments
};
```

4. Add to deploy nodes for remote deployment
5. Generate hardware config on target: `nixos-generate-config --show-hardware-config`

### Adding a New User

1. Create `modules/users/username.nix` with Home Manager config
2. Import in `flake.nix` under `home-manager.users.username`
3. Add user to host configuration in `users.users.username`

### Secrets Management

- **Use sops-nix** for all secrets (passwords, API keys, knock sequences)
- **Never commit unencrypted secrets** or private keys
- Secrets encrypted with GPG (admin) + age (per-host keys)
- Port knocking sequences stored in `secrets/vps/knock-sequences.yaml`

### Module Imports

- Common modules imported in `hosts/common/default.nix`
- Category configs imported from `hosts/categories/{category}.nix`
- Host configs import category + hardware config
- Networking modules (Tailscale, firewall) imported in category configs

## Host-Specific Notes

### bit (Main Laptop)

- Primary workstation and deployment hub
- Full development environment
- SSH agent with keys for remote operations

### spark (Framework Laptop)

- Framework-specific optimizations
- Lighter than bit, mobile-focused
- Framework kernel modules enabled

### hermes (Third Laptop)

- Minimal laptop config
- Secondary/backup machine

### VPS Hosts

- **Minimal and hardened** - kernel hardening, strict sysctls
- **Port knocking required** for SSH access
- Knock sequence encrypted in `secrets/vps/knock-sequences.yaml`
- Access via: `just knock vps-alpha`
- Auto-updates enabled (manual reboot)

## Security Considerations

### Pre-commit Hooks

- **nix-fmt**: Ensures all Nix files properly formatted
- **nix-flake-check**: Validates flake syntax and configuration
- **detect-secrets**: Scans for accidentally committed secrets
- **prevent-secrets**: Blocks hardcoded passwords, tokens, keys

### CI Pipeline

GitHub Actions runs on every push/PR:

- Flake validation (`nix flake check`)
- Format checking (`nix fmt -- --check`)
- Dry-run builds of all configurations
- Secret scanning (detect-secrets, hardcoded pattern checks)
- Private key detection

### Port Knocking

VPS hosts use port knocking for SSH access:

- Knock sequence defined in encrypted `secrets/vps/knock-sequences.yaml`
- Sequence must be knocked before SSH port opens (30 second window)
- Use: `just knock vps-alpha`
- Change sequences periodically for security

### Tailscale

All hosts connect via Tailscale mesh VPN:

- Zero-trust networking
- Use Tailscale hostnames for opaque addressing
- Firewall trusts Tailscale interface
- Enables secure deployment without exposing services

## File Modification Guidelines

### When Editing Nix Files

- Always run `just check` after significant changes
- Format with `just fmt` before committing
- Test with `nixos-rebuild build` before switching
- Verify no secrets are hardcoded

### Hardware Configuration

- `hosts/{category}/{hostname}/hardware-configuration.nix` generated by `nixos-generate-config`
- Can be regenerated but may contain manual tweaks
- Machine-specific: filesystems, boot, kernel modules, hardware settings

### Category Configuration

- Changes to `hosts/categories/{category}.nix` affect ALL hosts in that category
- Test changes across multiple hosts when possible
- Keep category configs focused on shared functionality

### Common Configuration

- Changes to `hosts/common/default.nix` affect **ALL hosts**
- Extremely conservative changes only
- Test across all categories

## Troubleshooting

### Build Failures

```bash
# Check syntax
just check

# Verify imports are correct
# Check for circular dependencies
# Check for conflicting options across modules
```

### Port Knocking Issues

```bash
# Check knock sequence in secrets
just secrets-view secrets/vps/knock-sequences.yaml

# Knock and connect
just knock vps-alpha

# Check knockd status on VPS
ssh vps-alpha 'sudo systemctl status knockd'

# Check firewall rules
ssh vps-alpha 'sudo iptables -L INPUT -v -n'
```

### Tailscale Connection Issues

```bash
# Check Tailscale status
just tailscale-status spark

# Restart Tailscale on host
ssh hostname 'sudo systemctl restart tailscaled'

# Check firewall allows Tailscale
ssh hostname 'sudo iptables -L -v -n | grep tailscale'
```

### SOPS Decryption Failures

```bash
# Check GPG key available
gpg --list-secret-keys

# Check age key on host
ssh hostname 'sudo cat /var/lib/sops-nix/key.txt'

# Verify .sops.yaml has correct keys
cat .sops.yaml

# Re-encrypt with updated keys
just secrets-update
```

### Rollback

```bash
# Rollback to previous generation
just rollback spark

# List all generations
just generations spark

# Clean old generations
just clean spark
```

## Quick Reference

```bash
# List all commands
just --list

# Install new host (fully automated)
just install <hostname> <category> <ip>

# Deploy to specific host
just deploy spark

# Deploy to all hosts
just deploy-all

# Update flake inputs
just update

# Edit secrets
just secrets

# Port knock VPS
just knock vps-alpha

# Sync from remote
just sync-remote spark

# Check system info
just info spark
just tailscale-status spark

# Rollback and cleanup
just rollback spark
just clean spark
```

## Documentation

- **`docs/WORKFLOW.md`**: Complete hands-off installation and deployment workflow
- **`docs/JUSTFILE_COMMANDS.md`**: Full command reference with examples
- **`docs/QUICK_START.md`**: Quick start guide
- **`docs/SOPS_GPG_SETUP.md`**: Secrets management with SOPS
- **`docs/STRUCTURE_OVERVIEW.md`**: Repository architecture
- **`README.md`**: Main repository documentation

## AI Assistant Best Practices

When assisting with this repository:

1. **Use justfile commands** - Never suggest old scripts or make commands
2. **Respect security** - Never suggest hardcoding secrets or bypassing encryption
3. **Follow categories** - Understand security differences between laptop/vps/server/experiment
4. **Test before deploy** - Always suggest `just check` and `just dry-run` before deployment
5. **Maintain opacity** - Use Tailscale hostnames, not IPs
6. **Preserve automation** - Leverage the automated installation workflow
7. **Document changes** - Suggest adding comments for non-standard configurations
8. **Security-first for VPS** - Port knocking, hardening, minimal packages are intentional
9. **Modular approach** - Use category configs for shared functionality
10. **Secrets via SOPS** - All sensitive data must be encrypted with SOPS
