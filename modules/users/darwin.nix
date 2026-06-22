{ lib
, userName ? "giovanni"
, ...
}:

{
  imports = [
    ./neovim
    ./runtimes-mise.nix
  ];

  home.username = lib.mkDefault userName;
  home.homeDirectory = lib.mkDefault "/Users/${userName}";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  # Darwin shell/profile dotfiles are owned by chezmoi. Keep NixVim from
  # generating Home Manager session files that would collide with them.
  programs.nixvim.defaultEditor = lib.mkForce false;

  # Neovim is intentionally owned by NixVim on Darwin.
  xdg.configFile."nvim/init.lua".force = true;

  # SSH base config — nix owns the skeleton; host entries live in
  # ~/.ssh/config.d/hosts managed by chezmoi (sensitive, not in repo).
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # OrbStack must come first (before any Host blocks).
    includes = [
      "~/.orbstack/ssh/config"
      "~/.ssh/config.d/*"
      "~/.config/devbox/ssh/config"
    ];
    matchBlocks."*" = {
      extraOptions = {
        AddKeysToAgent = "yes";
        IdentityAgent = "~/.bitwarden-ssh-agent.sock";
      };
    };
  };
}
