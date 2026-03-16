{ ... }:

{
  imports = [
    ./ssh-config.nix
    ./neovim
    ./packages
    ./runtimes-mise.nix
  ];

  # Home Manager configuration for user giovanni
  # This can be overridden per-host if needed

  home.username = "giovanni";
  home.homeDirectory = "/home/giovanni";

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Giovanni";
    userEmail = "your.email@example.com"; # Change this
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
