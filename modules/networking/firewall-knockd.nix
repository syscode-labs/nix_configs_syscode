{ config, pkgs, lib, ... }:

let
  # Port knocking sequence will be loaded from sops
  # This is just the module structure
  knockdConfig = ''
    [options]
      UseSyslog

    [openSSH]
      sequence    = ${builtins.concatStringsSep "," config.sops.placeholder."knockd/sequence"}
      seq_timeout = 15
      tcpflags    = syn
      command     = ${pkgs.iptables}/bin/iptables -I INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
      cmd_timeout = 30
      stop_command = ${pkgs.iptables}/bin/iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
  '';
in
{
  # Port knocking daemon configuration
  services.knockd = {
    enable = true;
    interface = "eth0"; # Override this per host as needed
    configFile = pkgs.writeText "knockd.conf" knockdConfig;
  };

  # Strict firewall - only allow established connections and port knocking
  networking.firewall = {
    enable = true;
    allowPing = false; # Stealth mode

    # No ports open by default - use port knocking
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];

    # Extra commands to set up port knocking
    extraCommands = ''
      # Allow established connections
      iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

      # Allow loopback
      iptables -A INPUT -i lo -j ACCEPT

      # Port knocking will temporarily open SSH
      # Default policy is to drop everything else
    '';
  };

  # Install knockd package
  environment.systemPackages = with pkgs; [
    knockd
  ];
}
