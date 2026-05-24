{ lib
, pkgs
, userName ? "nixos"
, userGitName ? userName
, userGitEmail ? "${userName}@localhost"
, ...
}:

let
  homeDirDefault =
    if pkgs.stdenv.isDarwin then "/Users/${userName}" else "/home/${userName}";
in
{
  imports = [
    ./packages
    ./runtimes-mise.nix
  ];

  # Home Manager configuration for selected user identity.
  # This can be overridden per-host if needed
  home.username = lib.mkDefault userName;
  home.homeDirectory = lib.mkDefault homeDirDefault;

  # Git configuration
  programs.git = {
    enable = true;
    settings = {
      user.name = userGitName;
      user.email = userGitEmail;
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # SSH configuration — private keys served via Bitwarden SSH agent.
  # Host-specific config is SOPS-encrypted and deployed to ~/.ssh/config.d/hosts
  # by the NixOS sops-nix module; see hosts/categories/laptops.nix.
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    includes = [ "~/.ssh/config.d/hosts" ];
    extraConfig = "IdentityAgent ~/.bitwarden-ssh-agent.sock";
  };

  # Shell configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "eza -la";
      cat = "bat";
    };
  };

  # Fish shell (if preferred)
  # programs.fish.enable = true;

  # This value determines the Home Manager release compatibility
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
