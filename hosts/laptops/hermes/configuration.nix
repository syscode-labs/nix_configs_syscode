{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../categories/nix-laptops.nix
  ];

  # Host identity (opaque)
  networking.hostName = "hermes";

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # MacBookPro11,1 wireless uses Broadcom STA.
  hardware.enableRedistributableFirmware = true;
  nixpkgs.config.permittedInsecurePackages = [
    "broadcom-sta-6.30.223.271-59-6.12.62"
  ];
  boot.kernelModules = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [ "bcma" "brcmsmac" ];

  # Keep the old MacBook awake when it is on AC power.
  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkForce "suspend";
    HandleLidSwitchExternalPower = "ignore";
    IdleAction = "ignore";
  };

  # The Thunderbolt Ethernet adapter can prevent MacBookPro11,1 suspend/resume.
  # Take the wired interface down only for the sleep window; keep lid wake active.
  powerManagement.powerDownCommands = ''
    if [ -e /sys/class/net/ens9 ]; then
      ${pkgs.iproute2}/bin/ip link set ens9 down || true
    fi
    if ${pkgs.gawk}/bin/awk '$1 == "XHC1" && $3 == "*enabled" { found = 1 } END { exit !found }' /proc/acpi/wakeup; then
      echo XHC1 > /proc/acpi/wakeup
    fi
  '';
  powerManagement.resumeCommands = ''
    if [ -e /sys/class/net/ens9 ]; then
      ${pkgs.iproute2}/bin/ip link set ens9 up || true
      ${pkgs.networkmanager}/bin/nmcli device connect ens9 || true
    fi
  '';

  home-manager.users.giovanni.wayland.windowManager.hyprland.settings.monitor =
    lib.mkForce ",preferred,auto,1.6";

  # Third laptop - lighter package set
  environment.systemPackages = with pkgs; [
    firefox
    vim
    git
  ];

  # Transitional recovery path while hermes is being brought under flake control.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "yes";
      PasswordAuthentication = lib.mkForce true;
      KbdInteractiveAuthentication = lib.mkForce true;
    };
  };

  system.stateVersion = "25.11";
}
