# NixOS Configuration Structure Overview

## Host Categories

This repository organizes hosts into four categories with different security postures and configurations:

### 📱 Laptops (bit, spark, hermes)

**Purpose**: Full-featured workstations for development and daily use

**Configuration**: `hosts/categories/laptops.nix`

**Features**:
- Desktop environment (GNOME/KDE/etc.)
- Full development tools (Docker, VSCode, etc.)
- Power management, Bluetooth, audio
- NetworkManager for WiFi
- Tailscale for secure connectivity

**Hosts**:
- **bit**: Main laptop, primary development machine
- **spark**: Framework laptop with Framework-specific optimizations
- **hermes**: Third laptop, minimal configuration

---

### ☁️ VPS (vps-alpha, ...)

**Purpose**: Minimal, hardened cloud instances for public-facing services

**Configuration**: `hosts/categories/vps.nix`

**Features**:
- **Kernel hardening**: slab_nomerge, init_on_alloc, PTI, etc.
- **Port knocking**: SSH only accessible after knock sequence
- **Minimal packages**: vim, htop, basic utils only
- **Auto-updates**: Automatic security updates
- **Aggressive firewall**: Default deny, Tailscale trusted
- **Resource optimized**: Swap enabled, strict limits

**Security**:
- AppArmor enabled
- Audit logging
- Locked kernel modules
- Strict sysctl settings
- No GUI, no unnecessary services

**Access**:
```bash
# Must knock before SSH
knock -v vps-alpha 7000 8000 9000
ssh giovanni@vps-alpha
```

---

### 🖥️ Servers (server-alpha, ...)

**Purpose**: On-premises servers for internal services

**Configuration**: `hosts/categories/servers.nix`

**Features**:
- Docker for containerized services
- Prometheus node exporter for monitoring
- Headless but less restrictive than VPS
- Larger package set for utilities
- Tailscale for secure access

**Use Cases**:
- Internal web services
- Database servers
- File servers
- Build servers

---

### 🧪 Experiments (experiment-alpha, ...)

**Purpose**: Testing, development, temporary configurations

**Configuration**: `hosts/categories/experiments.nix`

**Features**:
- Relaxed security for quick iteration
- Full development toolchain (gcc, gdb, strace, etc.)
- Docker enabled
- Keep derivations for faster rebuilds
- Scripting languages (Python, Node.js)

**Use Cases**:
- Testing new configurations
- Development VMs
- Temporary test environments
- Learning new technologies

---

## Directory Structure

```
.
├── flake.nix                           # Main configuration entry point
├── .sops.yaml                          # SOPS encryption configuration
│
├── hosts/
│   ├── common/
│   │   └── default.nix                 # Config shared by ALL hosts
│   │
│   ├── categories/
│   │   ├── laptops.nix                 # Shared laptop config
│   │   ├── vps.nix                     # Shared VPS config (hardened)
│   │   ├── servers.nix                 # Shared server config
│   │   └── experiments.nix             # Shared experiment config
│   │
│   ├── laptops/
│   │   ├── bit/
│   │   │   ├── configuration.nix       # bit-specific config
│   │   │   └── hardware-configuration.nix
│   │   ├── spark/
│   │   │   ├── configuration.nix       # spark-specific (Framework)
│   │   │   └── hardware-configuration.nix
│   │   └── hermes/
│   │       ├── configuration.nix
│   │       └── hardware-configuration.nix
│   │
│   ├── vps/
│   │   └── example-vps/
│   │       ├── configuration.nix
│   │       └── hardware-configuration.nix
│   │
│   ├── servers/
│   │   └── example-server/
│   │       ├── configuration.nix
│   │       └── hardware-configuration.nix
│   │
│   └── experiments/
│       └── example-experiment/
│           ├── configuration.nix
│           └── hardware-configuration.nix
│
├── modules/
│   ├── networking/
│   │   ├── tailscale.nix               # Tailscale VPN
│   │   ├── base-firewall.nix           # Base firewall + fail2ban + SSH hardening
│   │   └── firewall-knockd.nix         # Port knocking for VPS
│   │
│   ├── system/
│   │   └── security.nix                # System security hardening
│   │
│   └── users/
│       └── giovanni.nix                # Home Manager config
│
├── secrets/
│   ├── common/                         # Secrets for all hosts
│   ├── vps/
│   │   ├── knock-sequences.yaml        # Port knock sequences (encrypted)
│   │   └── .gitkeep
│   ├── laptops/
│   ├── servers/
│   └── experiments/
│
├── scripts/
│   ├── deploy.sh                       # Simple deployment
│   ├── pull-and-deploy.sh              # Pull from git then deploy
│   ├── sync-from-remote.sh             # Copy changes from remote
│   └── remote-git-push.sh              # Push using agent forwarding
│
└── docs/
    ├── DEPLOYMENT.md                   # Deployment guide
    ├── SOPS_GPG_SETUP.md               # Secrets setup guide
    ├── STRUCTURE_OVERVIEW.md           # This file
    └── QUICK_REFERENCE.md              # Command cheat sheet
```

## Configuration Inheritance

```
Individual Host (e.g., bit)
    ↓ imports
Category Config (laptops.nix)
    ↓ imports
Common Config (common/default.nix)
    ↓ imports
Networking Modules (tailscale, firewall)
System Modules (security)
```

### Example: bit Configuration Layers

1. **hardware-configuration.nix**: Filesystems, boot, hardware-specific
2. **bit/configuration.nix**: bit-specific packages, users, services
3. **categories/laptops.nix**: Desktop env, power mgmt, laptop packages
4. **common/default.nix**: Nix settings, locale, basic packages
5. **networking/tailscale.nix**: Tailscale configuration
6. **networking/base-firewall.nix**: Firewall, fail2ban, SSH hardening
7. **system/security.nix**: Security hardening
8. **users/giovanni.nix**: Home Manager config

## Security Model

### Network Security (All Hosts)

- **Tailscale**: Mesh VPN for all inter-host communication
- **Firewall**: Enabled with strict rules
- **SSH**: Key-only authentication, rate limiting, fail2ban
- **Fail2ban**: Active on all hosts

### VPS Additional Security

- **Port Knocking**: SSH port closed by default, opens after knock
- **Kernel Hardening**: PTI, SMAP, SMEP, various security features
- **AppArmor**: Mandatory access control
- **Audit Logging**: All exec() calls logged
- **Minimal Attack Surface**: Bare minimum packages, no GUI

### Secrets Management

- **SOPS**: Encrypted secrets with GPG + age
- **GPG**: Admin key for encrypting secrets from workstation
- **age**: Per-host keys, never leave the machine
- **No Plain Text**: All secrets encrypted at rest in git

## Opaque Addressing

Hosts are addressed opaquely to minimize information leakage:

1. **Tailscale Names**: Use Tailscale hostnames (bit, spark, etc.)
2. **SSH Config Aliases**: Define in `~/.ssh/config`, not in repo
3. **No IPs in Repo**: IP addresses not hardcoded
4. **Deploy via Tailscale**: All deployments over Tailscale mesh

Example SSH config:
```ssh
Host bit
  HostName bit.tailnet-name.ts.net
  User giovanni
  ForwardAgent yes

Host vps-alpha
  HostName vps-alpha.tailnet-name.ts.net  # Or configure knock script
  User giovanni
  ForwardAgent yes
```

## Adding New Hosts

### Laptop

```bash
# 1. Create directory
mkdir -p hosts/laptops/newhostname

# 2. Create configuration
cat > hosts/laptops/newhostname/configuration.nix <<EOF
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../categories/laptops.nix
  ];

  networking.hostName = "newhostname";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.giovanni = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "audio" ];
  };

  system.stateVersion = "24.11";
}
EOF

# 3. Generate hardware config on target machine
nixos-generate-config --show-hardware-config > hosts/laptops/newhostname/hardware-configuration.nix

# 4. Add to flake.nix
# nixosConfigurations.newhostname = mkHost { hostname = "newhostname"; category = "laptops"; };

# 5. Add to deploy.nodes
# newhostname = mkDeployNode { hostname = "newhostname"; configName = "newhostname"; };
```

### VPS

Same process but use `category = "vps"` and ensure port knocking configuration is added.

## Port Knocking

VPS hosts use port knocking for SSH access security.

### Setup

1. **Generate sequence**: Choose random ports (e.g., 7854, 3219, 9876)
2. **Add to secrets**: Edit `secrets/vps/knock-sequences.yaml`
3. **Encrypt**: `sops -e -i secrets/vps/knock-sequences.yaml`
4. **Reference in config**: Already configured in `modules/networking/firewall-knockd.nix`

### Usage

```bash
# Knock sequence
knock -v vps-alpha 7854 3219 9876

# Then immediately SSH (30 second window)
ssh giovanni@vps-alpha
```

### Client Script

```bash
#!/usr/bin/env bash
knock -v "$1" 7854 3219 9876 && sleep 1 && ssh "giovanni@$1"
```

## Deployment Workflows

### From Central Laptop (bit)

```bash
# Deploy to single host
deploy .#spark

# Deploy to all laptops
for host in bit spark hermes; do deploy ".#$host"; done

# Deploy to all VPS (knock first if needed)
for host in vps-alpha; do
  knock -v "$host" 7854 3219 9876
  deploy ".#$host"
done
```

### Update All Hosts

```bash
# Update flake inputs
nix flake update
git add flake.lock
git commit -m "update: flake inputs"
git push

# Deploy to all hosts
for host in bit spark hermes vps-alpha server-alpha; do
  deploy ".#$host"
done
```

## Best Practices

1. **Test locally first**: `nix flake check && nix build .#nixosConfigurations.hostname.config.system.build.toplevel`
2. **Dry run deployments**: `deploy .#hostname --dry-activate`
3. **Change knock sequences regularly**: Update `secrets/vps/knock-sequences.yaml` monthly
4. **Use Tailscale names**: Avoid hardcoding IPs
5. **Categorize appropriately**: Put hosts in correct category for proper security posture
6. **Keep categories focused**: Don't mix concerns between categories
7. **Document host-specific changes**: Add comments in host configs
8. **Rotate secrets**: Update API keys, tokens periodically
9. **Monitor VPS**: Check for unauthorized access attempts
10. **Backup configs**: This repo is your backup, keep it up to date

## Troubleshooting

See `AGENTS.md` for detailed troubleshooting commands and procedures.
