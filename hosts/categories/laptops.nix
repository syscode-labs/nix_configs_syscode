{ config, pkgs, ... }:

{
  # Common configuration for all laptop hosts

  imports = [
    ../common/default.nix
    ../../modules/networking/tailscale.nix
    ../../modules/networking/base-firewall.nix
  ];

  # SSH host config — topology kept encrypted; deployed to user's ~/.ssh/config.d/hosts
  sops.secrets.ssh_hosts_config = {
    sopsFile = ../../secrets/laptops/ssh-hosts.yaml;
    owner = "giovanni";
    path = "/home/giovanni/.ssh/config.d/hosts";
    mode = "0600";
  };

  # Laptop-specific settings
  powerManagement.enable = true;
  services.thermald.enable = true;

  # Networking
  networking.networkmanager.enable = true;

  # Sound
  services.pulseaudio.enable = false;
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

    # Password manager + SSH agent
    bitwarden-desktop
    bitwarden-cli
  ];

  # YubiKey udev rules (FIDO2/U2F access for non-root)
  services.udev.packages = with pkgs; [ yubikey-personalization libu2f-host ];
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", GROUP="plugdev", MODE="0660"
  '';
  users.groups.plugdev = { };

  # Laptop-specific services
  services.upower.enable = true;
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "lock";
    HandlePowerKeyLongPress = "poweroff";
  };

  # Enable CUPS for printing
  services.printing.enable = true;
}
