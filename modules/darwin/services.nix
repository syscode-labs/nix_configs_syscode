{ lib, pkgs, ... }:

{
  # Native nix-darwin service modules (prefer these over custom launchd jobs).
  services.postgresql.enable = lib.mkDefault true;
  services.redis.enable = lib.mkDefault true;
  services.eternal-terminal.enable = lib.mkDefault false;

  # Services without first-class nix-darwin modules can still be managed via
  # launchd with nixpkgs binaries when needed.
  launchd.daemons.openvpn = {
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = false;
      ProgramArguments = [
        "${pkgs.openvpn}/sbin/openvpn"
        "--config"
        "/etc/openvpn/openvpn.conf"
      ];
    };
  };

  launchd.daemons.unbound = {
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = false;
      ProgramArguments = [
        "${pkgs.unbound}/sbin/unbound"
        "-d"
        "-c"
        "/etc/unbound/unbound.conf"
      ];
    };
  };
}
