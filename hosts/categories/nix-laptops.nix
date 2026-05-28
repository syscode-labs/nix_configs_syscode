{ config, lib, pkgs, ... }:

{
  imports = [
    ./laptops.nix
    ../../modules/desktop/hyprland.nix
  ];

  sops.defaultSopsFile = ../../secrets/common/secrets.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets.tailscale_oauth_secret = { };
  sops.secrets.giovanni_hashed_password = { neededForUsers = true; };

  # Ensure the encrypted password is actually written for existing users.
  users.mutableUsers = false;

  users.users.giovanni = {
    isNormalUser = true;
    description = "Giovanni Ferri";
    shell = lib.mkForce pkgs.fish;
    hashedPasswordFile = config.sops.secrets.giovanni_hashed_password.path;
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "plugdev" ];
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDyv3qXnOMs2QwNPmoVwsCokSJBBDqCoQNIZ8NldVekbD4G6fz5p5cRo0ErjF0Z6T0iXa+wHfu/TcPJUd29xKnQ= giovanni@bit.lan"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfXaazSk3L5JdrJ/i41/8wGZeG6iwIdb8YAyzfmm8UK giovanni@bit.lan"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAABBBK+cBXxt5LdrJsuOHhFNCp8AyBTJKxiCee2thfRbqtZ9YNW6HcsqNXuXp7Z77Srg8CAWj1YYhYs1NjYrBcS/B2A= giovanni@bit.lan"
    ];
  };

  programs.fish.enable = true;

  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [{ command = "ALL"; options = [ "NOPASSWD" "SETENV" ]; }];
    }
  ];
}
