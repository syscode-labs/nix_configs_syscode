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

  # Reduce swap pressure on SSD
  boot.kernel.sysctl."vm.swappiness" = 10;

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
    jack.enable = true;
  };

  # Redistributable firmware (covers most WiFi/BT/GPU; no proprietary blobs)
  hardware.enableRedistributableFirmware = true;

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
    chezmoi

    # Common desktop apps
    firefox
    alacritty

    # Password manager + SSH agent
    bitwarden-desktop
    bitwarden-cli

    # Multimedia
    ffmpeg
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
  ];

  # YubiKey udev rules (FIDO2/U2F access for non-root)
  services.udev.packages = with pkgs; [ yubikey-personalization libu2f-host ];
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", GROUP="plugdev", MODE="0660"
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';

  # Set battery charge limit to 80% and make it writable for user toggle.
  # Done via systemd rather than udev because the EC resets the threshold
  # after the udev "add" event fires during boot.
  systemd.services.battery-charge-threshold = {
    description = "Set battery charge limit to 80%";
    after = [ "systemd-udev-settle.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.coreutils ];
    script = ''
      for bat in /sys/class/power_supply/BAT*; do
        [ -f "$bat/charge_control_end_threshold" ] || continue
        echo 80 > "$bat/charge_control_end_threshold"
        chmod a+w "$bat/charge_control_end_threshold"
      done
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
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
