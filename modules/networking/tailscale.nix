{ config, pkgs, lib, ... }:

{
  # Tailscale VPN
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
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
