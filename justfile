# NixOS Configuration Management
# Usage: just <command>

# Show available commands
default:
    @just --list

# Validate flake configuration
check:
    nix flake check

# Format all Nix files
fmt:
    nix fmt

# Format check without modifying
fmt-check:
    nix fmt -- --check .

# Update flake inputs
update:
    nix flake update
    @echo "Flake inputs updated. Review flake.lock and commit."

# Deploy to a specific host
deploy host:
    deploy .#{{host}}

# Deploy to all hosts
deploy-all:
    #!/usr/bin/env bash
    for host in bit spark hermes vps-alpha server-alpha; do
        echo "Deploying to $host..."
        deploy ".#$host"
    done

# Install new host (fully automated, zero manual steps)
install host category ip:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing {{host}} ({{category}}) from {{ip}}..."
    echo "This is fully automated - no manual steps required!"
    echo ""

    # Verify category
    if [[ ! -f "hosts/categories/{{category}}.nix" ]]; then
        echo "Error: Category '{{category}}' does not exist"
        echo "Available: laptops, vps, servers, experiments"
        exit 1
    fi

    # Create host directory
    mkdir -p "hosts/{{category}}/{{host}}"

    # Generate age key
    echo "[1/11] Generating age encryption key..."
    AGE_KEY=$(age-keygen 2>/dev/null)
    AGE_PUBLIC_KEY=$(echo "$AGE_KEY" | grep "public key:" | cut -d: -f2 | tr -d ' ')
    AGE_PRIVATE_KEY=$(echo "$AGE_KEY" | grep -v "public key:")

    mkdir -p ".bootstrap-temp/{{host}}"
    echo "$AGE_PRIVATE_KEY" > ".bootstrap-temp/{{host}}/age-key.txt"
    chmod 600 ".bootstrap-temp/{{host}}/age-key.txt"

    echo "✓ Age key: $AGE_PUBLIC_KEY"

    # Create install config
    echo "[2/11] Creating installation configuration..."
    cat > ".bootstrap-temp/{{host}}/configuration.nix" <<'NIXEOF'
    { config, pkgs, modulesPath, ... }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      networking.hostName = "{{host}}";
      networking.networkmanager.enable = true;
      services.openssh.enable = true;
      services.openssh.settings.PermitRootLogin = "no";
      services.openssh.settings.PasswordAuthentication = false;
      users.users.giovanni = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" ];
        openssh.authorizedKeys.keys = [ "$(cat ~/.ssh/id_ed25519.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub)" ];
      };
      nix.settings.experimental-features = [ "nix-command" "flakes" ];
      system.stateVersion = "24.11";
    }
    NIXEOF

    cat > ".bootstrap-temp/{{host}}/flake.nix" <<'FLAKEEOF'
    {
      inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      outputs = { nixpkgs, ... }: {
        nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./configuration.nix ];
        };
      };
    }
    FLAKEEOF

    # Install NixOS
    echo "[3/11] Installing NixOS (this takes ~10 minutes)..."
    ssh-keygen -R "{{ip}}" 2>/dev/null || true
    scp -o StrictHostKeyChecking=no -r ".bootstrap-temp/{{host}}" "root@{{ip}}:/tmp/install-config"

    ssh -o StrictHostKeyChecking=no "root@{{ip}}" bash <<'REMOTEEOF'
    set -euo pipefail
    DISK=$(lsblk -ndo NAME,TYPE | grep disk | head -n1 | awk '{print $1}')
    DISK="/dev/${DISK}"
    echo "Using disk: ${DISK}"
    parted ${DISK} -- mklabel gpt
    parted ${DISK} -- mkpart ESP fat32 1MiB 512MiB
    parted ${DISK} -- set 1 esp on
    parted ${DISK} -- mkpart primary 512MiB 100%
    if [[ ${DISK} == *"nvme"* ]] || [[ ${DISK} == *"mmcblk"* ]]; then
        mkfs.fat -F 32 -n boot ${DISK}p1
        mkfs.ext4 -L nixos ${DISK}p2
    else
        mkfs.fat -F 32 -n boot ${DISK}1
        mkfs.ext4 -L nixos ${DISK}2
    fi
    mount /dev/disk/by-label/nixos /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/boot /mnt/boot
    nixos-generate-config --root /mnt
    cp /tmp/install-config/*/configuration.nix /mnt/etc/nixos/
    nixos-install --no-root-passwd --no-channel-copy
    REMOTEEOF

    echo "✓ NixOS installed"

    # Wait for reboot
    echo "[4/11] Waiting for system to reboot..."
    sleep 30
    for i in {1..60}; do
        if ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no giovanni@{{ip}} "echo ready" 2>/dev/null; then
            break
        fi
        sleep 2
    done

    # Deploy age key
    echo "[5/11] Deploying age key..."
    ssh giovanni@{{ip}} "sudo mkdir -p /var/lib/sops-nix"
    scp ".bootstrap-temp/{{host}}/age-key.txt" giovanni@{{ip}}:/tmp/
    ssh giovanni@{{ip}} "sudo mv /tmp/age-key.txt /var/lib/sops-nix/key.txt && sudo chmod 600 /var/lib/sops-nix/key.txt && sudo chown root:root /var/lib/sops-nix/key.txt"

    # Get hardware config
    echo "[6/11] Fetching hardware configuration..."
    ssh giovanni@{{ip}} "nixos-generate-config --show-hardware-config" > "hosts/{{category}}/{{host}}/hardware-configuration.nix"

    # Create host config
    echo "[7/11] Creating host configuration..."
    cat > "hosts/{{category}}/{{host}}/configuration.nix" <<NIXCONF
    { config, pkgs, ... }:
    {
      imports = [ ./hardware-configuration.nix ../../categories/{{category}}.nix ];
      networking.hostName = "{{host}}";
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      sops = {
        defaultSopsFile = ../../../secrets/common/secrets.yaml;
        age.keyFile = "/var/lib/sops-nix/key.txt";
        secrets."tailscale/authkey" = {};
      };
      systemd.services.tailscale-autoconnect = {
        description = "Automatic Tailscale connection";
        after = [ "network-pre.target" "tailscale.service" ];
        wants = [ "network-pre.target" "tailscale.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
          sleep 2
          status=\$(''${pkgs.tailscale}/bin/tailscale status --json || echo "")
          if echo "\$status" | ''${pkgs.jq}/bin/jq -e '.BackendState == "Running"' > /dev/null; then
            exit 0
          fi
          if [[ -f \${config.sops.secrets."tailscale/authkey".path} ]]; then
            ''${pkgs.tailscale}/bin/tailscale up --authkey \$(cat \${config.sops.secrets."tailscale/authkey".path})
          fi
        '';
      };
      users.users.giovanni = {
        isNormalUser = true;
        extraGroups = [ "wheel" ] ++ (if "{{category}}" == "laptops" then [ "networkmanager" "docker" "video" "audio" ] else []);
        openssh.authorizedKeys.keys = [ "$(cat ~/.ssh/id_ed25519.pub 2>/dev/null || cat ~/.ssh/id_rsa.pub)" ];
      };
      system.stateVersion = "24.11";
    }
    NIXCONF

    # Update .sops.yaml
    echo "[8/11] Updating .sops.yaml..."
    if ! grep -q "&{{host}}_age" .sops.yaml; then
        sed -i.bak "/^keys:/a\\
      - \&{{host}}_age $AGE_PUBLIC_KEY
    " .sops.yaml
        if [[ "{{category}}" == "vps" ]]; then
            sed -i.bak "/path_regex: secrets\\/vps/,/age:/ s/age:/age:\\n          - *{{host}}_age/" .sops.yaml
        elif [[ "{{category}}" == "laptops" ]]; then
            sed -i.bak "/path_regex: secrets\\/laptops/,/age:/ s/age:/age:\\n          - *{{host}}_age/" .sops.yaml
        fi
        sed -i.bak "/path_regex: secrets\\/common/,/age:/ s/age:/age:\\n          - *{{host}}_age/" .sops.yaml
        rm -f .sops.yaml.bak
    fi

    # Update flake.nix
    echo "[9/11] Updating flake.nix..."
    if ! grep -q "{{host}} = mkHost" flake.nix; then
        UPPER_CAT=$(echo "{{category}}" | tr '[:lower:]' '[:upper:]')
        sed -i.bak "/# === ${UPPER_CAT}/a\\
          {{host}} = mkHost { hostname = \"{{host}}\"; category = \"{{category}}\"; };\\
    " flake.nix
    fi
    if ! grep -q "{{host}} = mkDeployNode" flake.nix; then
        sed -i.bak "/# $(echo {{category}} | sed 's/.*/\u&/')/a\\
          {{host}} = mkDeployNode { hostname = \"{{host}}\"; configName = \"{{host}}\"; };\\
    " flake.nix
    fi
    rm -f flake.nix.bak

    # Re-encrypt secrets
    echo "[10/11] Re-encrypting secrets..."
    if [[ -f secrets/common/secrets.yaml ]]; then
        sops updatekeys secrets/common/secrets.yaml
    fi

    # Commit
    git add -A
    git commit -m "add: {{host}} ({{category}}) - automated installation" || true

    # Deploy
    echo "[11/11] Deploying full configuration..."
    deploy ".#{{host}}"

    # Cleanup
    rm -rf ".bootstrap-temp/{{host}}"

    echo ""
    echo "✅ Installation Complete!"
    echo "Host: {{host}}"
    echo "Category: {{category}}"
    echo "Access: ssh giovanni@{{host}}"

# Pull changes from git and deploy
pull-deploy host:
    git pull
    deploy .#{{host}}

# Sync changes from remote host to local repo
sync-remote host:
    #!/usr/bin/env bash
    set -euo pipefail
    REMOTE_PATH="${REMOTE_PATH:-/etc/nixos}"
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    echo "Syncing configuration from {{host}}..."
    ssh "{{host}}" "cd $REMOTE_PATH && git diff --name-only" > "$TEMP_DIR/changed_files.txt"

    if [[ ! -s "$TEMP_DIR/changed_files.txt" ]]; then
        echo "No changes on {{host}}"
        exit 0
    fi

    echo "Changed files:"
    cat "$TEMP_DIR/changed_files.txt"

    while IFS= read -r file; do
        echo "Copying $file..."
        mkdir -p "$(dirname "$file")"
        scp "{{host}}:$REMOTE_PATH/$file" "$file"
    done < "$TEMP_DIR/changed_files.txt"

    echo ""
    echo "Files synced. Review with: git diff"

# Push changes from remote host using SSH agent forwarding
remote-push host branch="main":
    #!/usr/bin/env bash
    set -euo pipefail
    REMOTE_PATH="${REMOTE_PATH:-/etc/nixos}"

    echo "Pushing changes from {{host}} to git..."
    ssh -A "{{host}}" bash -s <<EOF
    set -euo pipefail
    cd "$REMOTE_PATH"
    if [[ -z \$(git status --porcelain) ]]; then
        echo "No changes to commit on {{host}}"
        exit 0
    fi
    git add .
    git commit -m "chore: update from {{host}} [$(date +%Y-%m-%d)]"
    git push origin "{{branch}}"
    echo "✓ Successfully pushed from {{host}}"
    EOF

# Edit encrypted secrets
secrets file="secrets/common/secrets.yaml":
    sops {{file}}

# View decrypted secrets
secrets-view file="secrets/common/secrets.yaml":
    sops -d {{file}}

# Update encryption keys for all secrets
secrets-update:
    #!/usr/bin/env bash
    for file in secrets/**/*.yaml; do
        if [[ -f "$file" && "$file" != *.example ]]; then
            echo "Updating keys for $file..."
            sops updatekeys "$file"
        fi
    done

# Set up pre-commit hooks
setup:
    nix-shell -p pre-commit --run "pre-commit install"
    @echo "✓ Pre-commit hooks installed"

# Run pre-commit checks manually
pre-commit:
    pre-commit run --all-files

# Port knock and SSH to VPS
knock host sequence="7854 3219 9876":
    knock -v {{host}} {{sequence}} && sleep 1 && ssh giovanni@{{host}}

# Check Tailscale status on host
tailscale-status host:
    ssh {{host}} sudo tailscale status

# Show system info for host
info host:
    @echo "System info for {{host}}:"
    @ssh {{host}} 'echo "Hostname: $(hostname)" && echo "Kernel: $(uname -r)" && echo "Uptime: $(uptime -p)" && echo "Tailscale: $(sudo tailscale status --json | jq -r .BackendState)"'

# Rollback host to previous generation
rollback host:
    ssh {{host}} sudo nixos-rebuild switch --rollback

# List generations on host
generations host:
    ssh {{host}} sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Clean old generations on host
clean host days="30":
    ssh {{host}} sudo nix-collect-garbage --delete-older-than {{days}}d

# Build configuration without deploying
build host:
    nix build .#nixosConfigurations.{{host}}.config.system.build.toplevel

# Show what would be deployed (dry run)
dry-run host:
    deploy .#{{host}} --dry-activate

# Initialize git repository
git-init:
    #!/usr/bin/env bash
    if [[ -d .git ]]; then
        echo "Git repository already initialized"
        exit 0
    fi
    git init
    git add .
    git commit -m "Initial commit: NixOS configuration"
    echo "✓ Git repository initialized"

# Create new host template
new-host host category:
    #!/usr/bin/env bash
    mkdir -p "hosts/{{category}}/{{host}}"
    echo "Created hosts/{{category}}/{{host}}"
    echo "Next: Run nixos-generate-config on target and copy hardware-configuration.nix"
