{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../categories/servers.nix
  ];

  networking.hostName = "server-alpha";

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  # Network configuration
  networking.interfaces.enp0s3.useDHCP = true;

  # Users
  users.users.giovanni = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
    ];
  };

  # Server-specific services go here

  system.stateVersion = "24.11";
}
