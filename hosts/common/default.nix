{ config, pkgs, ... }:

{
  # Common configuration shared across all hosts

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Locale settings
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/New_York"; # Change to your timezone

  # Common packages available system-wide
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    tree
    jq
  ];

  # Common system modules
  imports = [
    ../../modules/system/security.nix
  ];
}
