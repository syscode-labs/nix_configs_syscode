{ pkgs, ... }:

{
  # Non-runtime devops/security utilities. Runtime/versioned tools are
  # intentionally owned by mise in runtimes-mise.nix.
  home.packages = with pkgs; [
    aws-vault
    checkov
    oci-cli
    trivy
  ];
}
