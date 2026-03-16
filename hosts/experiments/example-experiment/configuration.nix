{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../categories/experiments.nix
  ];

  networking.hostName = "experiment-alpha";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Users
  users.users.giovanni = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
    ];
  };

  # Experimental features and testing

  system.stateVersion = "24.11";
}
