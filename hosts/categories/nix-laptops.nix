{ config, lib, pkgs, ... }:

let
  carveraController =
    let
      version = "2.1.0";
      srcs = {
        x86_64-linux = pkgs.fetchurl {
          url = "https://github.com/Carvera-Community/Carvera_Controller/releases/download/v${version}/carveracontroller-community-${version}-x86_64.appimage";
          sha256 = "0zixy68c2pkmvmf4ddlym27b5a8aikbrapw361bqrgqrvw1ij6cy"; # pragma: allowlist secret
        };
        aarch64-linux = pkgs.fetchurl {
          url = "https://github.com/Carvera-Community/Carvera_Controller/releases/download/v${version}/carveracontroller-community-${version}-aarch64.appimage";
          sha256 = "19wnk7wdzmr2sdlglwlzrjdwnxngx1mbqn23fnk8a918hzlywwv0"; # pragma: allowlist secret
        };
      };
    in
    pkgs.appimageTools.wrapAppImage {
      name = "carvera-controller";
      inherit version;
      src = srcs.${pkgs.stdenv.hostPlatform.system};
    };
in

{
  imports = [
    ./laptops.nix
    ../../modules/desktop/hyprland.nix
  ];

  sops.defaultSopsFile = ../../secrets/common/secrets.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets.tailscale_oauth_secret = { };
  sops.secrets.giovanni_hashed_password = { neededForUsers = true; };
  sops.secrets.fail2ban_nix_laptops_ignore_jail = {
    path = "/etc/fail2ban/jail.d/99-nix-laptops-ignore.local";
    mode = "0440";
    restartUnits = [ "fail2ban.service" ];
  };

  systemd.tmpfiles.rules = [
    "d /etc/fail2ban/jail.d 0755 root root -"
  ];

  # Ensure the encrypted password is actually written for existing users.
  users.mutableUsers = false;

  users.users.giovanni = {
    isNormalUser = true;
    description = "Giovanni Ferri";
    shell = lib.mkForce pkgs.fish;
    hashedPasswordFile = config.sops.secrets.giovanni_hashed_password.path;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "plugdev" "dialout" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDyv3qXnOMs2QwNPmoVwsCokSJBBDqCoQNIZ8NldVekbD4G6fz5p5cRo0ErjF0Z6T0iXa+wHfu/TcPJUd29xKnQ= giovanni@bit.lan"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfXaazSk3L5JdrJ/i41/8wGZeG6iwIdb8YAyzfmm8UK giovanni@bit.lan"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAABBBK+cBXxt5LdrJsuOHhFNCp8AyBTJKxiCee2thfRbqtZ9YNW6HcsqNXuXp7Z77Srg8CAWj1YYhYs1NjYrBcS/B2A= giovanni@bit.lan"
    ];
  };

  environment.systemPackages = [ carveraController ];

  # Carvera CNC controller USB access
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", MODE="0660", GROUP="dialout"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="10ce", ATTRS{idProduct}=="eb93", MODE="0660", GROUP="plugdev"
  '';

  programs.fish.enable = true;

  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [{ command = "ALL"; options = [ "NOPASSWD" "SETENV" ]; }];
    }
  ];
}
