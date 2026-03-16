# Justfile Commands Reference

All commands use `just` - a modern command runner with better syntax than Make.

## Installation Commands

### Install New Host (Fully Automated)
```bash
# Zero manual steps - completely hands-off
just install <hostname> <category> <ip>

# Examples
just install spark laptops 192.168.1.100
just install vps-beta vps 203.0.113.50
just install server-beta servers 10.0.0.50
just install test-vm experiments 192.168.1.200
```

**What it does:**
- Generates age encryption key
- Partitions & formats disk
- Installs NixOS
- Deploys age key
- Fetches hardware config
- Creates host configuration
- Updates .sops.yaml automatically
- Updates flake.nix automatically
- Re-encrypts secrets
- Commits changes
- Deploys full configuration

**Time:** ~15 minutes
**Manual steps:** 0

## Deployment Commands

### Deploy to Host
```bash
just deploy <hostname>

# Examples
just deploy spark
just deploy vps-alpha
```

### Deploy to All Hosts
```bash
just deploy-all
```

### Pull and Deploy
```bash
# Pull from git, then deploy
just pull-deploy spark
```

### Dry Run (See What Would Change)
```bash
just dry-run spark
```

### Build Without Deploying
```bash
just build spark
```

## Configuration Commands

### Validate Configuration
```bash
just check
```

### Format Nix Files
```bash
just fmt
```

### Format Check (No Modifications)
```bash
just fmt-check
```

### Update Flake Inputs
```bash
just update
```

## Secrets Management

### Edit Encrypted Secrets
```bash
# Default (common secrets)
just secrets

# Specific file
just secrets secrets/vps/knock-sequences.yaml
```

### View Decrypted Secrets
```bash
just secrets-view secrets/common/secrets.yaml
```

### Update Encryption Keys
```bash
# After adding new host, update all secrets
just secrets-update
```

## Remote Operations

### Sync from Remote Host
```bash
# Pull changes made on remote host to local repo
just sync-remote spark

# Then review and commit
git diff
git commit -am "sync from spark"
```

### Push from Remote Host
```bash
# Push changes from remote host using SSH agent forwarding
just remote-push spark

# With custom branch
just remote-push spark develop
```

## VPS Commands

### Port Knock and SSH
```bash
# Default sequence
just knock vps-alpha

# Custom sequence
just knock vps-alpha "7000 8000 9000"
```

## System Info

### Tailscale Status
```bash
just tailscale-status spark
```

### System Info
```bash
just info spark
```

### Rollback to Previous Generation
```bash
just rollback spark
```

### List Generations
```bash
just generations spark
```

### Clean Old Generations
```bash
# Default: 30 days
just clean spark

# Custom retention
just clean spark 14
```

## Development Commands

### Setup Pre-commit Hooks
```bash
just setup
```

### Run Pre-commit Checks
```bash
just pre-commit
```

### Initialize Git Repository
```bash
just git-init
```

### Create New Host Template
```bash
just new-host myhost laptops
```

## Quick Reference

```bash
# List all available commands
just --list

# Show help for specific command
just --show install

# Run command with verbose output
just --verbose deploy spark
```

## Common Workflows

### Install and Configure New Laptop
```bash
# 1. Boot installer, note IP
# 2. Install (one command, wait 15 min)
just install spark laptops 192.168.1.100

# 3. Done! Access via:
ssh giovanni@spark
```

### Update All Hosts
```bash
just update
git commit -am "update flake inputs"
just deploy-all
```

### Deploy Changes to Single Host
```bash
vim hosts/laptops/spark/configuration.nix
just deploy spark
```

### Install Hardened VPS
```bash
# Boot installer on VPS, note IP
just install vps-beta vps 203.0.113.50

# Access via port knocking
just knock vps-beta
```

### Sync Config from Remote
```bash
# Made changes on remote host
just sync-remote spark

# Review and commit
git diff
git commit -am "sync from spark"
git push

# Deploy to other hosts
just deploy hermes
```

## Tips

- **Tab completion**: Just supports shell completion, install with `just --completions bash > /etc/bash_completion.d/just`
- **Dry run**: Use `just --dry-run <command>` to see what would execute
- **Working directory**: Just runs from repo root automatically
- **Variables**: Commands use `{{variables}}` for clarity
- **Multi-line**: Complex commands use `#!/usr/bin/env bash` shebang

## Categories Reminder

- **laptops**: Full workstation (desktop, dev tools, docker)
- **vps**: Hardened cloud (minimal, port knocking, auto-updates)
- **servers**: On-premises (docker, monitoring)
- **experiments**: Development (full toolchain, relaxed security)

## See Also

- `docs/WORKFLOW.md` - Complete workflow and installation guide
- `docs/SOPS_GPG_SETUP.md` - Secrets management
- `AGENTS.md` - Architecture reference
- `.github/instructions.md` - GitHub Copilot instructions
