# GitHub Copilot Instructions

This NixOS configuration repository uses **categorized hosts** with automated zero-touch installation. All commands use `justfile`.

## Quick Reference

### Essential Commands

```bash
just --list                           # List all commands
just install <host> <cat> <ip>        # Install new host (fully automated)
just deploy <hostname>                # Deploy configuration
just deploy-all                       # Deploy to all hosts
just check                            # Validate flake
just fmt                              # Format Nix files
just update                           # Update flake inputs
just secrets                          # Edit encrypted secrets
just knock <vps>                      # Port knock and SSH to VPS
```

### Repository Structure

```
flake.nix                   # Main flake, defines all hosts
justfile                    # All commands (replaces Make/scripts)
hosts/
  categories/               # Category-specific configs
    laptops.nix            # Full workstations
    vps.nix                # Hardened cloud instances
    servers.nix            # On-premises servers
    experiments.nix        # Development/testing
  {category}/{hostname}/   # Individual host configs
modules/
  networking/              # Tailscale, firewall, port knocking
  system/                  # Security modules
  users/                   # Home Manager configs
secrets/                   # SOPS-encrypted secrets
```

## Host Categories

- **laptops** (bit, spark, hermes): Full workstation with desktop, dev tools, Docker
- **vps** (vps-alpha, ...): Hardened minimal cloud with port knocking, auto-updates
- **servers** (server-alpha, ...): On-premises with Docker, monitoring
- **experiments** (test-vm, ...): Development with relaxed security

## Adding a New Host

**Automated (recommended):**
```bash
# Boot NixOS installer on target, then:
just install spark laptops 192.168.1.100
# Wait ~15 min - completely hands-off
```

**Manual:**
1. Create `hosts/{category}/{hostname}/configuration.nix`
2. Add to `flake.nix` nixosConfigurations using `mkHost`
3. Add to `deploy.nodes` for remote deployment

## Security Rules

1. **Never hardcode secrets** - use SOPS encryption
2. **All secrets via `just secrets`** - edit `secrets/common/secrets.yaml`
3. **Port knocking for VPS** - sequences in `secrets/vps/knock-sequences.yaml`
4. **Tailscale for all hosts** - use hostnames, not IPs
5. **SSH key-only auth** - no passwords
6. **Run `just check` before commit** - validates all configs
7. **Format with `just fmt`** - before committing Nix files

## Secrets Management

```bash
just secrets                                    # Edit common secrets
just secrets secrets/vps/knock-sequences.yaml   # Edit VPS secrets
just secrets-view <file>                        # View decrypted
just secrets-update                             # Re-encrypt after adding host
```

**All secrets encrypted with SOPS (GPG + age). Never commit unencrypted secrets.**

## Common Patterns

### Deploying Changes

```bash
vim hosts/laptops/spark/configuration.nix
just deploy spark
```

### Updating All Hosts

```bash
just update                  # Update flake inputs
git commit -am "update flake"
just deploy-all             # Deploy everywhere
```

### VPS Access (Port Knocking)

```bash
just knock vps-alpha        # Knocks and opens SSH
```

### Rollback

```bash
just rollback spark         # Rollback to previous generation
just generations spark      # List all generations
```

## Module Organization

- **Common modules** in `hosts/common/default.nix` - affect ALL hosts
- **Category configs** in `hosts/categories/` - affect all hosts in category
- **Host configs** in `hosts/{category}/{hostname}/` - host-specific only
- **Network modules** in `modules/networking/` - Tailscale, firewall, knockd
- **User modules** in `modules/users/` - Home Manager configurations

## Best Practices

1. **Use category configs** for shared functionality within a category
2. **Test with dry-run** before deploying: `just dry-run spark`
3. **Validate before commit**: `just check && just fmt`
4. **Use Tailscale names** for addressing (opaque, no IPs in code)
5. **Per-host hardware-configuration.nix** is auto-generated
6. **Category changes affect all hosts** in that category - test carefully
7. **Common changes affect ALL hosts** - be extremely conservative
8. **VPS hardening is intentional** - minimal packages, port knocking, kernel hardening

## Troubleshooting

```bash
just check                           # Validate flake syntax
just dry-run <host>                  # See what would change
just rollback <host>                 # Rollback to previous generation
just tailscale-status <host>         # Check Tailscale connection
just info <host>                     # System information
ssh <host> 'journalctl -xe'         # View system logs
```

## Development Workflow

```bash
nix develop                          # Enter dev shell (has all tools)
just check                           # Validate all configs
just fmt                             # Format all Nix files
just build <host>                    # Build without deploying
```

## Documentation

- `AGENTS.md` - Complete AI assistant reference
- `docs/WORKFLOW.md` - Installation and deployment workflow
- `docs/JUSTFILE_COMMANDS.md` - Full command reference
- `docs/SOPS_GPG_SETUP.md` - Secrets management guide
- `README.md` - Main repository documentation

## Automated Installation Features

The `just install` command does everything automatically:
1. Generates age encryption key
2. Partitions/formats disk
3. Installs NixOS
4. Deploys age key
5. Fetches hardware config
6. Creates host configuration
7. Updates .sops.yaml
8. Updates flake.nix
9. Re-encrypts secrets
10. Commits to git
11. Deploys full config

**Result: Fully configured system in ~15 minutes with zero manual steps.**

## Key Files

- `flake.nix` - Host definitions, uses `mkHost` helper
- `justfile` - All commands (install, deploy, secrets, etc.)
- `.sops.yaml` - SOPS encryption configuration (GPG + age keys)
- `hosts/common/default.nix` - Shared config for ALL hosts
- `hosts/categories/{category}.nix` - Category-specific configs
- `secrets/common/secrets.yaml` - Encrypted common secrets (Tailscale authkey, etc.)
- `secrets/vps/knock-sequences.yaml` - Encrypted port knock sequences

## When Suggesting Code

- Use `just` commands, not scripts or make
- Respect host categories and their security levels
- Never suggest hardcoding secrets
- Always validate with `just check`
- Format with `just fmt`
- Test with `just dry-run` before deploying
- Use Tailscale hostnames, not IPs
- Maintain zero-touch installation automation
- Follow DRY principle with `mkHost` helper
- Keep VPS configs minimal and hardened
