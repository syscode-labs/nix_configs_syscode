{
  description = "NixOS configuration with categorized hosts and centralized deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, deploy-rs, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };

    # Helper function to create NixOS configurations
    mkHost = { hostname, category, extraModules ? [] }:
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${category}/${hostname}/configuration.nix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.giovanni = import ./modules/users/giovanni.nix;
          }
        ] ++ extraModules;
      };

    # Helper to create deploy-rs nodes
    # Uses Tailscale hostnames for opaque addressing
    mkDeployNode = { hostname, configName }:
      {
        # Use Tailscale hostname for maximum opacity
        # Format: hostname.tailnet-name.ts.net
        # Or just use the short name if configured in /etc/hosts or SSH config
        hostname = "${hostname}"; # Override in hosts file or use Tailscale name

        profiles.system = {
          user = "root";
          sshUser = "giovanni";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.${configName};
        };
      };
  in
  {
    # NixOS Configurations organized by category
    nixosConfigurations = {
      # === LAPTOPS ===
      bit = mkHost {
        hostname = "bit";
        category = "laptops";
      };

      spark = mkHost {
        hostname = "spark";
        category = "laptops";
      };

      hermes = mkHost {
        hostname = "hermes";
        category = "laptops";
      };

      # === VPS ===
      vps-alpha = mkHost {
        hostname = "example-vps";
        category = "vps";
      };

      # Add more VPS hosts here as needed
      # vps-beta = mkHost {
      #   hostname = "vps-beta";
      #   category = "vps";
      # };

      # === SERVERS ===
      server-alpha = mkHost {
        hostname = "example-server";
        category = "servers";
      };

      # Add more servers here
      # server-beta = mkHost {
      #   hostname = "server-beta";
      #   category = "servers";
      # };

      # === EXPERIMENTS ===
      experiment-alpha = mkHost {
        hostname = "example-experiment";
        category = "experiments";
      };
    };

    # Deploy-rs configuration for remote deployments
    # Hostnames are intentionally opaque - use Tailscale or SSH config aliases
    deploy.nodes = {
      # Laptops - typically deployed via Tailscale
      bit = mkDeployNode {
        hostname = "bit";
        configName = "bit";
      };

      spark = mkDeployNode {
        hostname = "spark";
        configName = "spark";
      };

      hermes = mkDeployNode {
        hostname = "hermes";
        configName = "hermes";
      };

      # VPS - access via Tailscale or configure in ~/.ssh/config
      vps-alpha = mkDeployNode {
        hostname = "vps-alpha";
        configName = "vps-alpha";
      };

      # Servers
      server-alpha = mkDeployNode {
        hostname = "server-alpha";
        configName = "server-alpha";
      };

      # Experiments
      experiment-alpha = mkDeployNode {
        hostname = "experiment-alpha";
        configName = "experiment-alpha";
      };
    };

    # Deploy-rs checks
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    # Development shell with deployment tools
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        deploy-rs.packages.${system}.deploy-rs
        just
        nixos-anywhere
        git
        openssh
        sops
        age
        gnupg
        pre-commit
        knockd # For port knocking
        jq
        mkpasswd
      ];

      shellHook = ''
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║  NixOS Configuration Development Environment            ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "Available Hosts:"
        echo "  Laptops:      bit, spark, hermes"
        echo "  VPS:          vps-alpha"
        echo "  Servers:      server-alpha"
        echo "  Experiments:  experiment-alpha"
        echo ""
        echo "Quick Start:"
        echo "  just --list                     - Show all commands"
        echo "  just install spark laptops IP   - Install new host (zero manual steps)"
        echo "  just deploy bit                 - Deploy to host"
        echo "  just check                      - Validate configuration"
        echo ""
        echo "Installation Example:"
        echo "  just install spark laptops 192.168.1.100"
        echo ""
        echo "Documentation:"
        echo "  docs/WORKFLOW.md                - Complete workflow guide"
        echo "  docs/AUTOMATED_INSTALLATION.md  - Zero-touch install guide"
        echo "  docs/SOPS_GPG_SETUP.md          - Secrets management"
        echo ""
      '';
    };
  };
}
