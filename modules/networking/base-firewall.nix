{ config, pkgs, lib, ... }:

{
  # Base firewall configuration for all hosts
  # Tailscale and port knocking are added via separate modules

  networking.firewall = {
    enable = true;

    # Allow ping from Tailscale network only
    allowPing = lib.mkDefault true;

    # Log refused connections
    logRefusedConnections = true;
    logRefusedPackets = false; # Reduce spam

    # SSH abuse handling is delegated to fail2ban. Avoid iptables recent-based
    # rate limiting here because it can lock out trusted LAN/Tailscale clients
    # before fail2ban's ignore list gets a say.
  };

  # Fail2ban for additional protection
  services.fail2ban = {
    enable = true;
    maxretry = 10;
    bantime = "1h";
    ignoreIP = [
      "127.0.0.1/8"
      "::1"
      "10.10.210.0/23" # LAN
      "fdcf:e578:c293::/64" # LAN IPv6
      "100.64.0.0/10" # Tailscale CGNAT range
      "fd7a:115c:a1e0::/48" # Tailscale IPv6 range
    ];
  };

  systemd.services.fail2ban.serviceConfig.ExecStartPost = pkgs.writeShellScript "fail2ban-clear-stale-bans" ''
    ${pkgs.fail2ban}/bin/fail2ban-client unban --all || true
  '';

  # SSH hardening
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      MaxAuthTries = 6;
    };

    # Use stronger algorithms
    extraConfig = ''
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
      MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
      KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
    '';
  };
}
