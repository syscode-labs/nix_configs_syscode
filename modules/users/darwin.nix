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
}
