{ config, pkgs, lib, ... }:

{
  # Common configuration for server hosts

  imports = [
    ../common/default.nix
    ../../modules/networking/tailscale.nix
    ../../modules/networking/base-firewall.nix
  ];

  # Servers are headless
  services.xserver.enable = false;

  # Boot configuration
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda"; # Override per host
  };

  # Server-specific packages
  environment.systemPackages = with pkgs; [
    vim
    htop
    iotop
    tmux
    screen
    rsync
    ncdu
    lsof
  ];

  # Enable Docker for containerized services
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Monitoring
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    port = 9100;
  };

  # Automatic cleanup
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = lib.mkForce "--delete-older-than 14d";
  };
}
