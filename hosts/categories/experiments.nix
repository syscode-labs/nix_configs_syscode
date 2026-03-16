{ config, pkgs, ... }:

{
  # Configuration for experimental/testing hosts

  imports = [
    ../common/default.nix
    ../../modules/networking/tailscale.nix
    ../../modules/networking/base-firewall.nix
  ];

  # Less restrictive settings for experiments
  networking.firewall.allowPing = true;

  # Development tools
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    strace
    ltrace
    gdb
    valgrind

    # Build tools
    gcc
    gnumake
    pkg-config

    # Scripting
    python3
    nodejs
  ];

  # Allow containers for testing
  virtualisation.docker.enable = true;

  # More relaxed Nix settings for experiments
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" "repl-flake" ];
    keep-outputs = true;
    keep-derivations = true;
  };
}
