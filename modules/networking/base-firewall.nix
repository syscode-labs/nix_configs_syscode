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

    # Rate limiting for SSH (when opened via knock)
    extraCommands = ''
      # Rate limit SSH connections to prevent brute force
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
      iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
    '';
  };

  # Fail2ban for additional protection
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "24h";
    ignoreIP = [
      "127.0.0.1/8"
      "100.64.0.0/10" # Tailscale CGNAT range
    ];
  };

  # SSH hardening
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      MaxAuthTries = 3;
    };

    # Use stronger algorithms
    extraConfig = ''
      Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
      MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
      KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
    '';
  };
}
