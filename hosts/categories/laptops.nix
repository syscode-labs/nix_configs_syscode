{ config, pkgs, ... }:

{
  # Common configuration for all laptop hosts

  imports = [
    ../common/default.nix
    ../../modules/networking/tailscale.nix
    ../../modules/networking/base-firewall.nix
  ];

  # Laptop-specific settings
  powerManagement.enable = true;
  services.thermald.enable = true;

  # Networking
  networking.networkmanager.enable = true;

  # Sound
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Display/Desktop environment packages
  services.xserver = {
    enable = true;
    xkb.layout = "us";
  };

  # Common laptop packages
  environment.systemPackages = with pkgs; [
    # Power management
    powertop
    acpi

    # Network tools
    networkmanagerapplet

    # Laptop utilities
    brightnessctl

    # Common desktop apps
    firefox
    alacritty
  ];

  # Laptop-specific services
  services.upower.enable = true;
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchDocked = "ignore";
  };

  # Enable CUPS for printing
  services.printing.enable = true;
}
