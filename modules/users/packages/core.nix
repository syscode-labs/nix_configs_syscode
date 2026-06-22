{ lib, pkgs, ... }:

{
  # Core user-facing CLI utilities.
  home.packages = with pkgs; [
    age
    bat
    chezmoi
    delta
    eza
    fd
    fzf
    ripgrep
    pay-respects
    starship
    zoxide
  ] ++ lib.optionals (!pkgs.stdenv.isDarwin) [
    bitwarden-cli
  ];
}
