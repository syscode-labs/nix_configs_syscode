{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../categories/vps.nix
  ];

  # Host identity (opaque - use Tailscale hostname for access)
  networking.hostName = "vps-alpha";

  # VPS-specific boot (GRUB for most VPS providers)
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda"; # Common for VPS - adjust if needed
  };

  # Network interface - adjust based on VPS provider
  networking.interfaces.ens3.useDHCP = true;

  # Port knocking interface
  services.knockd.interface = "ens3";

  # Users - minimal for VPS
  users.users.giovanni = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
    ];
  };

  # VPS-specific services can go here
  # For example, reverse proxy, web server, etc.

  system.stateVersion = "24.11";
}
