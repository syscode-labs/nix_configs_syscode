{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../categories/nix-laptops.nix
  ];

  networking.hostName = "nyx";

  # ── Boot ──────────────────────────────────────────────────────────────────
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # boot.kernelPackages managed by apple-t2 nixos-hardware module (T2-patched kernel)
  # S0ix (s2idle) is the correct sleep mode for MacBook Air 2019 (T2)
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

  # ── Locale ────────────────────────────────────────────────────────────────
  time.timeZone = lib.mkForce "Europe/London";
  i18n.defaultLocale = lib.mkForce "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # ── Hardware ──────────────────────────────────────────────────────────────
  # apple-t2 nixos-hardware module (applied via flake extraModules) handles:
  # T2 keyboard/trackpad, audio UCM profiles, touch bar
  hardware.enableAllFirmware = true;
  # Enable automatic BCM4364 WiFi + Bluetooth firmware management via t2linux
  hardware.apple-t2.firmware.enable = true;

  # ── VMware guest support (remove when installing on bare metal) ───────────
  virtualisation.vmware.guest.enable = true;

  # ── Sound ─────────────────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── SSH ───────────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = lib.mkForce true;
  };

  # ── Packages ──────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
  ];

  system.stateVersion = "25.05";
}
