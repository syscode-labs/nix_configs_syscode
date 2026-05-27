{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../categories/laptops.nix
    ../../../modules/desktop/hyprland.nix
  ];

  networking.hostName = "titan";

  # ── Secrets ───────────────────────────────────────────────────────────────
  sops.defaultSopsFile = ../../../secrets/common/secrets.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets.tailscale_oauth_secret = { };
  sops.secrets.giovanni_hashed_password = { neededForUsers = true; };

  # ── Boot ──────────────────────────────────────────────────────────────────
  boot.initrd.kernelModules = [ "vfat" "nls_cp437" "nls_iso8859-1" "usbhid" ];
  # S3 (deep) is not supported on this hardware; s2idle (S0ix) is the correct mode
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];
  boot.blacklistedKernelModules = [ "sp5100_tco" "cros_usbpd_charger" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # linux-firmware ships MT7922 BT firmware zstd-compressed; enable kernel decompression
  boot.kernelPatches = [{
    name = "fw-compress-zstd";
    patch = null;
    extraConfig = "FW_LOADER_COMPRESS_ZSTD y";
  }];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
    timeout = 0;
  };

  boot.plymouth.enable = true;

  # ── LUKS / FIDO2 ──────────────────────────────────────────────────────────
  # systemd stage-1 handles FIDO2 unlock (slot 3) via systemd-cryptenroll.
  # Slot 2 is a plain recovery passphrase fallback.
  # token-timeout=10: wait 10 s for the YubiKey before falling back to prompt.
  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices."nixos-enc" = {
    device = "/dev/nvme0n1p2";
    preLVM = true;
    crypttabExtraOpts = [ "fido2-device=auto" "token-timeout=10" ];
  };

  # ── Kernel crash dump ─────────────────────────────────────────────────────
  # Reserves 256 MB for the capture kernel; on panic kexec boots it and
  # makedumpfile writes the core to /var/crash.  A boot-time service then
  # syncs any dumps to bookofshadows:/mnt/user/crash-dumps over NFS.
  boot.crashDump = {
    enable = true;
    reservedMemory = "256M";
  };

  fileSystems."/var/crash/remote" = {
    device = "10.10.210.59:/mnt/user/crash-dumps";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "_netdev"
      "soft"
      "timeo=10"
      "retrans=3"
    ];
  };

  systemd.services.kdump-sync = {
    description = "Upload kernel crash dumps to Unraid (bookofshadows)";
    after = [ "network-online.target" "var-crash-remote.automount" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      shopt -s nullglob
      dumps=(/var/crash/[0-9]* /var/crash/vmcore*)
      [[ ''${#dumps[@]} -eq 0 ]] && exit 0
      mkdir -p /var/crash/remote/titan
      for d in "''${dumps[@]}"; do
        cp -r "$d" /var/crash/remote/titan/ && rm -rf "$d"
        echo "kdump-sync: uploaded $d"
      done
    '';
  };

  # ── Filesystem maintenance ─────────────────────────────────────────────────
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # ── Firmware (Framework Laptop 13 AMD) ────────────────────────────────────
  services.fwupd.enable = true;
  # Pinned to get fwupd 1.9.7 for fingerprint sensor firmware downgrade
  services.fwupd.package = (import
    (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/bb2009ca185d97813e75736c2b8d1d8bb81bde05.tar.gz";
      sha256 = "sha256:003qcrsq5g5lggfrpq31gcvj82lb065xvr7bpfa8ddsw8x4dnysk";
    })
    {
      system = pkgs.stdenv.hostPlatform.system;
    }).fwupd;

  # ── Locale overrides (common/default.nix sets en_US/New York) ─────────────
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

  console.keyMap = "us";
  services.xserver.xkb.variant = "intl";

  # ── Hardware ──────────────────────────────────────────────────────────────
  hardware.enableAllFirmware = true;
  services.fprintd.enable = true;

  security.pam.u2f = {
    enable = true;
    settings.cue = true;
  };

  security.pam.services.hyprlock = {
    fprintAuth = true;
    u2fAuth = true;
  };
  security.pam.services.login = {
    fprintAuth = true;
    u2fAuth = true;
  };
  security.pam.services.greetd = {
    fprintAuth = true;
    u2fAuth = true;
    # Without this override, greetd's PAM stack sets try_first_pass on pam_unix,
    # which causes it to replay a cached (wrong) password on retry instead of
    # prompting fresh. Disabling forces a new password prompt each time.
    rules.auth.unix.settings.try_first_pass = lib.mkForce false;
  };

  # ── Sound ─────────────────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── User ──────────────────────────────────────────────────────────────────
  # Immutable shadow: NixOS always writes hashedPasswordFile to /etc/shadow.
  # With mutableUsers = true (default), NixOS skips the password update for
  # existing users — hashedPasswordFile is silently ignored (NixOS FIXME in
  # update-users-groups.pl). Setting false fixes this.
  users.mutableUsers = false;

  users.users.giovanni = {
    isNormalUser = true;
    description = "Giovanni Ferri";
    shell = pkgs.fish;
    hashedPasswordFile = config.sops.secrets.giovanni_hashed_password.path;
    extraGroups = [ "networkmanager" "wheel" "docker" "video" "audio" "plugdev" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDyv3qXnOMs2QwNPmoVwsCokSJBBDqCoQNIZ8NldVekbD4G6fz5p5cRo0ErjF0Z6T0iXa+wHfu/TcPJUd29xKnQ= giovanni@bit.lan"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfXaazSk3L5JdrJ/i41/8wGZeG6iwIdb8YAyzfmm8UK giovanni@bit.lan"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBK+cBXxt5LdrJsuOHhFNCp8AyBTJKxiCee2thfRbqtZ9YNW6HcsqNXuXp7Z77Srg8CAWj1YYhYs1NjYrBcS/B2A= giovanni@bit.lan"
    ];
  };

  programs.fish.enable = true;

  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
    }
  ];

  # ── Programs & services ───────────────────────────────────────────────────
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = lib.mkForce true;
  };

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  services.printing.enable = true;

  # ── Packages ──────────────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    vimPlugins.LazyVim
    neovim
    git
    wget
    curl
    glances
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        bbenoist.nix
        ms-python.python
        ms-azuretools.vscode-docker
        ms-vscode-remote.remote-ssh
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "remote-ssh-edit";
          publisher = "ms-vscode-remote";
          version = "0.47.2";
          sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
        }
      ];
    })
  ];

  fonts.packages = with pkgs; [
    corefonts
    vista-fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];
  fonts.fontDir.enable = true;

  system.stateVersion = "23.11";
}
