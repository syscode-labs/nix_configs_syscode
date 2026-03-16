{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../categories/laptops.nix
  ];

  # Host identity (opaque)
  networking.hostName = "spark";

  # Framework laptop specific settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Framework laptop hardware optimizations
  hardware.framework.enableKmod = true; # Framework specific kernel modules

  # Desktop environment
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Framework-specific packages
  environment.systemPackages = with pkgs; [
    # Framework utilities
    fw-ectool

    # Development
    vscode
    git
  ];

  # Users
  users.users.giovanni = {
    isNormalUser = true;
    description = "Giovanni";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
    ];
  };

  system.stateVersion = "24.11";
}
