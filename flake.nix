{
  description = "NixOS configuration with categorized hosts and multi-architecture support";

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
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, deploy-rs, nixvim, ... }@inputs:
    let
      # Machine-agnostic identity defaults (override via env when needed).
      defaultUser =
        let u = builtins.getEnv "NIXCFG_USER";
        in if u != "" then u else "giovanni";
      defaultGitName =
        let n = builtins.getEnv "NIXCFG_GIT_NAME";
        in if n != "" then n else defaultUser;
      defaultGitEmail =
        let e = builtins.getEnv "NIXCFG_GIT_EMAIL";
        in if e != "" then e else "${defaultUser}@localhost";

      # Supported architectures
      supportedSystems = [
        "x86_64-linux" # Intel/AMD 64-bit
        "aarch64-linux" # ARM 64-bit (including Ampere)
        "x86_64-darwin" # Intel Mac
        "aarch64-darwin" # Apple Silicon (M1/M2/M3)
      ];

      # Helper to generate attribute sets for all systems
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Per-system package sets
      pkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      );

      # Helper function to create NixOS configurations with architecture support
      mkHost =
        { hostname
        , category
        , system ? "x86_64-linux"
        , # Default to x86_64-linux for backwards compatibility
          userName ? defaultUser
        , userGitName ? defaultGitName
        , userGitEmail ? defaultGitEmail
        , extraModules ? [ ]
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              inputs
              userName
              userGitName
              userGitEmail
              ;
          };
          modules = [
            ./hosts/${category}/${hostname}/configuration.nix
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            {
              nixpkgs.config.allowUnfree = true;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit userName userGitName userGitEmail;
              };
              home-manager.users.${userName} = import ./modules/users/giovanni.nix;
              home-manager.sharedModules = [
                nixvim.homeManagerModules.nixvim
              ];
            }
          ] ++ extraModules;
        };

      # Helper to create deploy-rs nodes with architecture awareness
      mkDeployNode =
        { hostname
        , configName
        , system ? "x86_64-linux"
        , # Default to x86_64-linux
          sshUser ? defaultUser
        }:
        {
          # Use SSH config hostname (managed by our ssh-config module)
          hostname = "${hostname}";

          profiles.system = {
            user = "root";
            inherit sshUser;
            # Dynamically select the correct deploy-rs lib based on system
            path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${configName};
          };
        };
    in
    {
      # NixOS Configurations organized by category and architecture
      nixosConfigurations = {
        # === LAPTOPS (x86_64) ===
        bit = mkHost {
          hostname = "bit";
          category = "laptops";
          system = "x86_64-linux";
        };

        spark = mkHost {
          hostname = "spark";
          category = "laptops";
          system = "x86_64-linux";
        };

        hermes = mkHost {
          hostname = "hermes";
          category = "laptops";
          system = "x86_64-linux";
        };

        # === LAPTOPS (ARM - Apple Silicon example) ===
        # Uncomment when you have ARM laptops
        # macbook = mkHost {
        #   hostname = "macbook";
        #   category = "laptops";
        #   system = "aarch64-darwin";
        # };

        # === VPS (x86_64) ===
        vps-alpha = mkHost {
          hostname = "example-vps";
          category = "vps";
          system = "x86_64-linux";
        };

        # === VPS (ARM/Ampere - Example) ===
        # Uncomment when you have ARM-based VPS (e.g., Oracle Ampere, AWS Graviton)
        # vps-arm = mkHost {
        #   hostname = "vps-arm";
        #   category = "vps";
        #   system = "aarch64-linux";
        # };

        # === SERVERS (x86_64) ===
        server-alpha = mkHost {
          hostname = "example-server";
          category = "servers";
          system = "x86_64-linux";
        };

        # === SERVERS (ARM - Example for Raspberry Pi, Ampere, etc.) ===
        # server-arm = mkHost {
        #   hostname = "server-arm";
        #   category = "servers";
        #   system = "aarch64-linux";
        # };

        # === EXPERIMENTS ===
        experiment-alpha = mkHost {
          hostname = "example-experiment";
          category = "experiments";
          system = "x86_64-linux";
        };
      };

      # Deploy-rs configuration for remote deployments
      # Architecture is automatically handled based on host system
      deploy.nodes = {
        # Laptops (x86_64)
        bit = mkDeployNode {
          hostname = "bit";
          configName = "bit";
          system = "x86_64-linux";
        };

        spark = mkDeployNode {
          hostname = "spark";
          configName = "spark";
          system = "x86_64-linux";
        };

        hermes = mkDeployNode {
          hostname = "hermes";
          configName = "hermes";
          system = "x86_64-linux";
        };

        # VPS (x86_64)
        vps-alpha = mkDeployNode {
          hostname = "vps-alpha";
          configName = "vps-alpha";
          system = "x86_64-linux";
        };

        # Servers (x86_64)
        server-alpha = mkDeployNode {
          hostname = "server-alpha";
          configName = "server-alpha";
          system = "x86_64-linux";
        };

        # Experiments
        experiment-alpha = mkDeployNode {
          hostname = "experiment-alpha";
          configName = "experiment-alpha";
          system = "x86_64-linux";
        };

        # Example ARM deployments (uncomment as needed)
        # vps-arm = mkDeployNode {
        #   hostname = "vps-arm";
        #   configName = "vps-arm";
        #   system = "aarch64-linux";
        # };
      };

      # Deploy-rs checks
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      # Development shells for all supported architectures
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
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
              jq
              asciinema
              mkpasswd
            ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
              pkgs.knockd # For port knocking (Linux only)
            ];

            shellHook = ''
              echo "╔══════════════════════════════════════════════════════════╗"
              echo "║  NixOS Configuration Development Environment            ║"
              echo "║  Architecture: ${system}                                 ║"
              echo "╚══════════════════════════════════════════════════════════╝"
              echo ""
              echo "Available Hosts by Architecture:"
              echo "  x86_64-linux:"
              echo "    Laptops:      bit, spark, hermes"
              echo "    VPS:          vps-alpha"
              echo "    Servers:      server-alpha"
              echo "    Experiments:  experiment-alpha"
              echo ""
              echo "  aarch64-linux:"
              echo "    (Add ARM hosts in flake.nix)"
              echo ""
              echo "Quick Start:"
              echo "  just --list                     - Show all commands"
              echo "  just install spark laptops IP   - Install new host"
              echo "  just deploy bit                 - Deploy to host"
              echo "  just check                      - Validate configuration"
              echo ""
              echo "Adding ARM hosts:"
              echo "  Edit flake.nix and set system = \"aarch64-linux\""
              echo ""
              echo "Documentation:"
              echo "  docs/WORKFLOW.md                - Complete workflow guide"
              echo "  docs/MULTI_ARCH.md              - Multi-architecture guide"
              echo "  docs/SOPS_GPG_SETUP.md          - Secrets management"
              echo ""
            '';
          };
        }
      );

      # Expose package sets for all systems
      packages = forAllSystems (system: {
        # Expose useful packages per-system
        default = pkgsFor.${system}.hello;
      });

      # Formatter for all systems
      formatter = forAllSystems (system: pkgsFor.${system}.nixpkgs-fmt);
    };
}
