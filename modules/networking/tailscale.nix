{ config, pkgs, lib, ... }:

{
  # Tailscale VPN
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    authKeyFile = lib.mkIf (config.sops.secrets ? tailscale_oauth_secret)
      config.sops.secrets.tailscale_oauth_secret.path;
  };

  # Open Tailscale port in firewall
  networking.firewall = {
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # Ensure tailscale service starts on boot
  systemd.services.tailscaled.wantedBy = lib.mkForce [ "multi-user.target" ];
}
