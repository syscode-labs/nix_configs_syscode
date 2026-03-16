{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../categories/laptops.nix
  ];

  # Host identity (opaque)
  networking.hostName = "hermes";

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Desktop environment
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Third laptop - lighter package set
  environment.systemPackages = with pkgs; [
    firefox
    vim
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
