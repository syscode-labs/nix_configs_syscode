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
  boot.kernelModules = [ "wl" "thunderbolt" "tg3" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [ "bcma" "brcmsmac" ];

  services.hardware.bolt.enable = true;

  # Keep the old MacBook awake when it is on AC power.
  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkForce "suspend";
    HandleLidSwitchExternalPower = "ignore";
    IdleAction = "ignore";
  };

  # MacBookPro11,1 Thunderbolt Ethernet uses tg3. Treat suspend as a software
  # detach/reattach boundary so the adapter remains usable without keeping the
  # Thunderbolt NIC active through S3.
  powerManagement.powerDownCommands = ''
    for dev in /sys/class/net/*; do
      [ -e "$dev" ] || continue
      iface="''${dev##*/}"
      driver="$(${pkgs.coreutils}/bin/readlink -f "$dev/device/driver" 2>/dev/null || true)"
      if [ "''${driver##*/}" = tg3 ]; then
        ${pkgs.networkmanager}/bin/nmcli device disconnect "$iface" || true
        ${pkgs.iproute2}/bin/ip link set "$iface" down || true
      fi
    done
    ${pkgs.kmod}/bin/modprobe -r tg3 || true

    if ${pkgs.gawk}/bin/awk '$1 == "XHC1" && $3 == "*enabled" { found = 1 } END { exit !found }' /proc/acpi/wakeup; then
      echo XHC1 > /proc/acpi/wakeup
    fi
  '';
  powerManagement.resumeCommands = ''
    ${pkgs.kmod}/bin/modprobe tg3 || true
    ${pkgs.coreutils}/bin/sleep 2

    for dev in /sys/class/net/*; do
      [ -e "$dev" ] || continue
      iface="''${dev##*/}"
      driver="$(${pkgs.coreutils}/bin/readlink -f "$dev/device/driver" 2>/dev/null || true)"
      if [ "''${driver##*/}" = tg3 ]; then
        ${pkgs.iproute2}/bin/ip link set "$iface" up || true
        ${pkgs.networkmanager}/bin/nmcli device connect "$iface" || true
      fi
    done
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
