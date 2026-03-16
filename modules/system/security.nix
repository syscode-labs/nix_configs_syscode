{ config, pkgs, ... }:

{
  # Security hardening settings

  # Firewall
  networking.firewall.enable = true;

  # Sudo security
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=15
  '';

  # SOPS for secrets management
  # Secrets should be encrypted and stored separately
  # Example sops configuration:
  # sops.defaultSopsFile = ../../secrets/secrets.yaml;
  # sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # Additional security settings
  security.protectKernelImage = true;
}
