# NixOS Configuration

Personal NixOS configuration using flakes, with categorized hosts (laptops, VPS, servers, experiments) and fully automated zero-touch installation. Supports centralized deployment from a main laptop to remote machines without storing git credentials anywhere.

## Repository Structure

```
.
├── flake.nix                 # Main flake configuration
├── mise.toml                 # Primary task runner (validation/security)
├── justfile                  # Legacy operational commands (install/deploy)
├── hosts/                    # Host-specific configurations by category
│   ├── categories/          # Category-specific base configurations
│   │   ├── laptops.nix      # Full workstation config
│   │   ├── vps.nix          # Hardened minimal cloud instances
│   │   ├── servers.nix      # On-premises server config
│   │   └── experiments.nix  # Development/testing config
│   ├── laptops/             # Laptop hosts (bit, spark, hermes)
│   ├── vps/                 # VPS hosts
│   ├── servers/             # Server hosts
│   └── experiments/         # Experiment hosts
├── modules/
│   ├── users/               # User-specific configurations (home-manager)
│   │   └── giovanni.nix
│   ├── system/              # System-level modules
│   └── networking/          # Network configuration (Tailscale, firewall, etc.)
├── secrets/                 # Encrypted secrets (SOPS)
│   ├── common/              # Shared secrets
│   └── vps/                 # VPS-specific secrets (knock sequences)
├── ssh-config/              # SSH configuration examples
└── docs/                    # Documentation
    ├── WORKFLOW.md          # Complete workflow guide
    ├── JUSTFILE_COMMANDS.md # Command reference
    ├── QUICK_START.md       # Quick start guide
    ├── SOPS_GPG_SETUP.md    # Secrets management
    └── STRUCTURE_OVERVIEW.md # Architecture overview
```

## Prerequisites

- NixOS or Nix with flakes enabled
- Git
- GPG key for secrets encryption

## Identity and Machine-Agnostic Defaults

This repo supports user identity overrides without editing module code.

- `NIXCFG_USER` (default: `nixos`)
- `NIXCFG_GIT_NAME` (default: `NIXCFG_USER`)
- `NIXCFG_GIT_EMAIL` (default: `<NIXCFG_USER>@localhost`)

Example:

```bash
export NIXCFG_USER="$USER"
export NIXCFG_GIT_NAME="Your Name"
export NIXCFG_GIT_EMAIL="you@example.com"
```

These values are consumed by flake outputs and Home Manager user module wiring.

## Quick Start

📹 **New to this setup?** Watch the [5-minute quick start tutorial](docs/tutorials/01-quick-start.cast) to see the fully automated installation in action.

**See `docs/WORKFLOW.md` for complete installation workflow.**

1. **Clone this repository:**
   ```bash
   git clone <your-repo-url> ~/nix-config
   cd ~/nix-config
   ```

2. **Install task toolchain and list tasks:**
   ```bash
   mise install
   mise tasks ls
   ```

3. **Enter development environment:**
   ```bash
   nix develop
   ```

4. **Set up GPG for secrets:**
   ```bash
   gpg --full-generate-key
   # Update .sops.yaml with your GPG fingerprint
   # See docs/SOPS_GPG_SETUP.md for details
   ```

5. **Create Tailscale authkey:**
   ```bash
   # Visit: https://login.tailscale.com/admin/settings/keys
   # Generate reusable authkey
   # Add to secrets/common/secrets.yaml
   sops secrets/common/secrets.yaml
   ```

6. **Run CI-equivalent validation locally (mise-first):**
   ```bash
   mise run ci-validate
   mise run ci-security
   ```

7. **Install a new host (fully automated):**
   ```bash
   # Boot NixOS installer on target, note IP
   # NOTE: currently still routed through legacy just command path
   just install <hostname> <category> <ip>

   # Example: Install Framework laptop
   just install spark laptops 192.168.1.100
   ```

**That's it! The system installs completely hands-off in ~15 minutes.**

## Common Commands

### Mise-first validation and CI parity

```bash
# Show available tasks
mise tasks ls

# Formatting
mise run fmt
mise run fmt-check

# Flake validation
mise run flake-check

# Dry-run canonical build target
mise run build-dryrun

# CI-equivalent pipelines
mise run ci-validate
mise run ci-security
```

### Development Environment

Enter the development shell with all tools (deploy-rs, git, sops, etc.):
```bash
nix develop
```

### Local Deployment (on the machine itself)

Build and switch to new configuration:
```bash
sudo nixos-rebuild switch --flake .#laptop
```

Build without switching (test configuration):
```bash
sudo nixos-rebuild build --flake .#laptop
```

### Operational commands (mise-first)

Use `mise` tasks for deploy and secrets workflows.

### Remote Deployment (from central laptop)

Deploy to a remote machine:
```bash
HOST=<hostname> mise run deploy

# Examples
HOST=spark mise run deploy
HOST=vps-alpha mise run deploy
```

Pull latest changes and deploy:
```bash
HOST=<hostname> mise run pull-deploy
```

Sync changes made on remote machine back to central repo:
```bash
HOST=<hostname> mise run sync-remote
# Then review, commit, and push
```

### Update flake inputs (update nixpkgs, home-manager, etc.)
```bash
mise run update
```

### Legacy compatibility commands
```bash
# Still available during migration window:
just --list
```

### Build specific output without installing
```bash
nix build .#nixosConfigurations.laptop.config.system.build.toplevel
```

## Adding a New Host

**Fully automated - zero manual steps on target:**

```bash
# Boot NixOS installer on target machine, note IP
just install <hostname> <category> <ip>

# Examples:
just install spark laptops 192.168.1.100      # Laptop
just install vps-beta vps 203.0.113.50        # VPS
just install server-alpha servers 10.0.0.50   # Server
just install test-vm experiments 192.168.1.200 # Experiment
```

The install command automatically:
- Partitions and installs NixOS
- Generates and deploys age encryption key
- Creates host configuration
- Updates .sops.yaml and flake.nix
- Re-encrypts all secrets
- Commits changes to git
- Deploys full configuration

**See `docs/WORKFLOW.md` for complete details.**

## Secrets Management

This repository uses **sops-nix** with GPG and age for secrets encryption.

### Edit encrypted secrets:
```bash
mise run secrets                                     # Edit common secrets
FILE=secrets/vps/knock-sequences.yaml mise run secrets
```

### View decrypted secrets:
```bash
FILE=secrets/common/secrets.yaml mise run secrets-view
```

### Update encryption keys (after adding new host):
```bash
mise run secrets-update
```

**See `docs/SOPS_GPG_SETUP.md` for complete setup guide.**

**Important:** Never commit unencrypted secrets, private keys, or sensitive data to this repository.

## Host Categories

Each host category has different security and functionality profiles:

- **laptops** (bit, spark, hermes): Full workstation with desktop, dev tools, Docker
- **vps** (vps-alpha, ...): Hardened minimal cloud instances with port knocking, auto-updates
- **servers** (server-alpha, ...): On-premises servers with Docker, monitoring
- **experiments** (test-vm, ...): Development/testing with relaxed security

See `docs/STRUCTURE_OVERVIEW.md` for architecture details.

## Security Features

- **Pre-commit hooks** validate Nix files and scan for secrets before commits
- **GitHub Actions CI** runs `mise` tasks for validation/security on every push
- **detect-secrets** scans for accidentally committed secrets
- **sops-nix** integration with GPG + age for encrypted secrets management
- **Tailscale mesh VPN** for secure inter-host communication
- **Port knocking** for SSH access on VPS hosts
- **Hardened kernel** and AppArmor on VPS
- **fail2ban** for SSH brute force protection
- **SSH agent forwarding** for credential-less git operations on remote machines

## Development

### Primary task entrypoint
```bash
mise tasks ls
```

## Troubleshooting

### Rollback to previous generation
```bash
just rollback <hostname>
```

### List generations
```bash
just generations <hostname>
```

### Clean old generations
```bash
just clean <hostname>        # Keep last 30 days
just clean <hostname> 14     # Keep last 14 days
```

### Dry run deployment (see what would change)
```bash
just dry-run <hostname>
```

### Check system info
```bash
just info <hostname>
just tailscale-status <hostname>
```

## Documentation

- **`docs/WORKFLOW.md`** - Complete hands-off installation and deployment workflow
- **`docs/ARCHITECTURE_FLOWS.md`** - Layer model and architecture/decision flow diagrams
- **`docs/MISE_TASKS_AND_CI.md`** - Mise-first task model and CI parity
- **`docs/JUSTFILE_COMMANDS.md`** - Full command reference with examples
- **`docs/QUICK_START.md`** - Quick start guide
- **`docs/SOPS_GPG_SETUP.md`** - Secrets management with SOPS
- **`docs/STRUCTURE_OVERVIEW.md`** - Repository architecture
- **`AGENTS.md`** - AI assistant reference guide

## Quick Commands Reference

```bash
# List mise tasks
mise tasks ls

# Run CI-equivalent checks locally
mise run ci-validate
mise run ci-security

# Deploy + sync operations
HOST=<hostname> mise run deploy
HOST=<hostname> mise run pull-deploy
HOST=<hostname> mise run sync-remote
HOST=<hostname> BRANCH=main mise run remote-push

# Secrets operations
mise run secrets
FILE=secrets/common/secrets.yaml mise run secrets-view
mise run secrets-update

# Flake input update
mise run update

# Legacy path for host bootstrap/install (until migrated)
just --list
just install <host> <category> <ip>
```
