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
    enableDefaultConfig = false;
    includes = [ "~/.ssh/config.d/hosts" ];
    extraConfig = "IdentityAgent ~/.bitwarden-ssh-agent.sock";
    matchBlocks."*".addKeysToAgent = "yes";
  };

  # Shell configuration
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "eza -la";
      cat = "bat";
    };
  };

  # Fish shell — plugins managed declaratively; no OMF needed on Linux.
  # interactiveShellInit is intentionally absent: chezmoi's config.fish owns it.
  programs.fish = {
    enable = true;
    plugins = [
      { name = "done"; src = pkgs.fishPlugins.done.src; }
      { name = "sponge"; src = pkgs.fishPlugins.sponge.src; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      { name = "plugin-git"; src = pkgs.fishPlugins.plugin-git.src; }
    ];
  };

  # This value determines the Home Manager release compatibility
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
