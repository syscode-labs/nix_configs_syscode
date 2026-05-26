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

  # Fish shell — plugins managed declaratively; no OMF needed.
  programs.fish = {
    enable = true;
    plugins = [
      { name = "tide"; src = pkgs.fishPlugins.tide.src; }
      { name = "done"; src = pkgs.fishPlugins.done.src; }
      { name = "sponge"; src = pkgs.fishPlugins.sponge.src; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair.src; }
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      { name = "plugin-git"; src = pkgs.fishPlugins.plugin-git.src; }
    ];
    interactiveShellInit = ''
      set -e fish_greeting
      set -gx EDITOR vim
      set -gx GOPATH "$HOME/go"
      set -gx GRANTED_ENABLE_AUTO_REASSUME true
      set -gx ENABLE_EXPERIMENTAL_MCP_CLI true

      if test -f "$HOME/.config/bitwarden/secrets.fish"
          source "$HOME/.config/bitwarden/secrets.fish"
      end

      mise activate fish | source
      zoxide init --cmd cd fish | source

      fish_add_path "$HOME/go/bin"
      fish_add_path "$HOME/.krew/bin"
      fish_add_path "$HOME/bin"
    '';
  };

  # This value determines the Home Manager release compatibility
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
