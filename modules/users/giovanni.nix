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
    userName = userGitName;
    userEmail = userGitEmail;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
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
