{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../categories/laptops.nix
  ];

  # Host identity (opaque)
  networking.hostName = "bit";

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Desktop environment - customize as needed
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Additional packages for main laptop
  environment.systemPackages = with pkgs; [
    # Development
    vscode
    docker-compose

    # Communication
    slack
    discord

    # Productivity
    obsidian
  ];

  # Enable Docker
  virtualisation.docker.enable = true;

  # Users - main laptop has full user config
  users.users.giovanni = {
    isNormalUser = true;
    description = "Giovanni";
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "audio" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      # "ssh-ed25519 AAAA..."
    ];
  };

  system.stateVersion = "24.11";
}
