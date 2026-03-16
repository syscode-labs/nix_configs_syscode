{ lib, pkgs, ... }:

let
  # These tools overlap with brew installs and should be version-owned by mise.
  runtimeTools = {
    awscli = "2.24.22";
    direnv = "2.21.3";
    gh = "2.45.0";
    go = "1.25.8";
    helm = "3.14.1";
    jq = "1.8.1";
    kubectl = "1.35.2";
    kubectx = "0.9.4";
    minikube = "1.37.0";
    neovim = "stable";
    node = "23.9.0";
    opentofu = "1.11.5";
    packer = "1.15.0";
    python = "3.13.12";
    shellcheck = "0.11.0";
    sops = "3.12.1";
    task = "3.49.1";
    terraform = "1.9.8";
    terraform-docs = "0.21.0";
    tflint = "0.55.1";
    tmux = "3.6a";
    trivy = "0.69.3";
    yq = "4.52.4";
  };
in
{
  # Keep version ownership centralized in mise, not mixed across package managers.
  programs.mise.enable = true;

  # Ensure the executable is present even when the HM program module does not add it.
  home.packages = [ pkgs.mise ];

  xdg.configFile."mise/config.toml".text = lib.concatStringsSep "\n"
    (
      [ "[tools]" ]
        ++ map (name: "${name} = \"${runtimeTools.${name}}\"")
        (builtins.attrNames runtimeTools)
    ) + "\n";
}
