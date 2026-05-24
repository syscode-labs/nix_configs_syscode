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

  # SSH configuration — private keys stored in Bitwarden SSH agent
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    # Bitwarden desktop exposes an SSH agent; use it for all connections
    extraConfig = "IdentityAgent ~/.bitwarden-ssh-agent.sock";
    matchBlocks = {
      "bookofshadows" = {
        user = "root";
        identityFile = "~/.ssh/personal-nw7";
      };
      "www.syscode.uk" = {
        user = "root";
        hostname = "159.89.249.76";
        identityFile = "~/.ssh/syscode-vps";
      };
      "192.168.50.118" = {
        hostname = "192.168.50.118";
        user = "giovanni";
        identityFile = "~/.ssh/personal-nw7";
      };
      "octopi-* fluiddpi*" = {
        user = "pi";
        identityFile = "~/.ssh/octopi";
        serverAliveInterval = 60;
        serverAliveCountMax = 60;
      };
      "homeassistant" = {
        user = "hassio";
        identityFile = "~/.ssh/personal-nw7";
        serverAliveInterval = 60;
        serverAliveCountMax = 60;
      };
      "dragonfly" = {
        user = "pi";
        identityFile = "~/.ssh/personal-nw7";
        extraOptions = { TCPKeepAlive = "no"; };
      };
      "ender5" = {
        user = "dietpi";
        identityFile = "~/.ssh/personal-nw7";
        extraOptions = { TCPKeepAlive = "no"; };
      };
      "micro1" = {
        user = "ubuntu";
        hostname = "145.241.219.11";
        identityFile = "~/.ssh/syscode-vps";
        extraOptions = { TCPKeepAlive = "no"; };
      };
      "ladybug" = {
        user = "pi";
        identityFile = "~/.ssh/personal-nw7";
        serverAliveInterval = 60;
        serverAliveCountMax = 60;
      };
      "dietpi-vm" = {
        user = "dietpi";
        identityFile = "~/.ssh/personal-nw7";
        forwardAgent = true;
      };
      "wrt54gs" = {
        user = "root";
        hostname = "192.168.111.1";
        extraOptions = {
          KexAlgorithms = "+diffie-hellman-group1-sha1";
          Ciphers = "+aes128-cbc";
          HostKeyAlgorithms = "+ssh-rsa,ssh-dss";
        };
      };
      "zeropi" = {
        user = "root";
        hostname = "192.168.122.180";
        extraOptions = {
          KexAlgorithms = "+diffie-hellman-group1-sha1";
          Ciphers = "+aes128-cbc";
          HostKeyAlgorithms = "+ssh-rsa,ssh-dss";
        };
      };
      "wrt-london wrt-london.wind-bearded.ts.net" = {
        user = "root";
        hostname = "wrt-london.wind-bearded.ts.net";
      };
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
