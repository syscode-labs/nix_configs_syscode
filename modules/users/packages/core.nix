{ pkgs, ... }:

{
  # Core user-facing CLI utilities.
  home.packages = with pkgs; [
    age
    bat
    bitwarden-cli
    chezmoi
    delta
    eza
    fd
    fzf
    ripgrep
  ];
}
