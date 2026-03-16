{ config, pkgs, lib, ... }:

{
  # Minimal, hardened configuration for VPS hosts

  imports = [
    ../common/default.nix
    ../../modules/networking/tailscale.nix
    ../../modules/networking/base-firewall.nix
    ../../modules/networking/firewall-knockd.nix
  ];

  # VPS are headless - no GUI
  services.xserver.enable = lib.mkForce false;

  # Minimal boot
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda"; # Common VPS disk - override per host if needed
  };

  # Kernel hardening
  boot.kernelParams = [
    "slab_nomerge"
    "init_on_alloc=1"
    "init_on_free=1"
    "page_alloc.shuffle=1"
    "pti=on"
    "vsyscall=none"
    "debugfs=off"
    "oops=panic"
  ];

  # Security hardening
  security.lockKernelModules = true;
  security.protectKernelImage = true;
  security.forcePageTableIsolation = true;
  security.apparmor.enable = true;

  # Disable unnecessary services
  services.printing.enable = lib.mkForce false;
  services.avahi.enable = lib.mkForce false;
  sound.enable = lib.mkForce false;

  # Automatic updates for security
  system.autoUpgrade = {
    enable = true;
    allowReboot = false; # Manual reboot for VPS
    dates = "04:00";
    flake = "github:yourusername/nix-configs"; # Update this
  };

  # Minimal package set
  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    wget
    git
    tmux
    rsync
  ];

  # Aggressive swap configuration for low-memory VPS
  swapDevices = [{
    device = "/swapfile";
    size = 2048; # 2GB swap
  }];

  # Resource limits
  systemd.extraConfig = ''
    DefaultLimitNOFILE=65536
  '';

  # Audit logging
  security.auditd.enable = true;
  security.audit.enable = true;
  security.audit.rules = [
    "-a exit,always -F arch=b64 -S execve"
  ];

  # Strict sysctl settings
  boot.kernel.sysctl = {
    # Network security
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_syncookies" = 1;

    # IPv6 privacy
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;

    # Kernel hardening
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 2;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
  };

  # Minimal SSH access via Tailscale or port knocking only
  services.openssh.listenAddresses = [
    { addr = "0.0.0.0"; port = 22; }
  ];
}
