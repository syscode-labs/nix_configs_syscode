{ pkgs, userName, ... }:

{
  networking.hostName = "bit";
  networking.computerName = "bit";

  system.primaryUser = userName;

  nixpkgs.config.allowUnfree = true;

  # ── Nix ───────────────────────────────────────────────────────────────────
  # Match pre-Sequoia/pre-nix-darwin nixbld IDs from the existing Nix install
  ids.uids.nixbld = 300;
  ids.gids.nixbld = 30000;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ── Shell ─────────────────────────────────────────────────────────────────
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  # ── System packages (via nixpkgs, not brew) ───────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    mise
    pay-respects
    fastfetch
    just
  ];

  # ── Homebrew ──────────────────────────────────────────────────────────────
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "none"; # flip to "uninstalled" once you've verified the list
      autoUpdate = false;
      upgrade = false;
    };

    taps = [
      "bufbuild/buf"
      "cloudflare/cloudflare"
      "common-fate/granted"
      "datreeio/datree"
      "derailed/k9s"
      "dhth/tap"
      "fielding/tap"
      "gcenx/wine"
      "git-chglog/git-chglog"
      "gromgit/fuse"
      "hidetatz/tap"
      "homebrew/cask"
      "homebrew/cask-fonts"
      "homebrew/cask-versions"
      "homebrew/core"
      "homebrew/services"
      "johanhaleby/kubetail"
      "kdash-rs/kdash"
      "ksonnet/tap"
      "lance0/tap"
      "liamg/tfsec"
      "manaflow-ai/cmux"
      "marcus/tap"
      "mengbo/ch340g-ch34g-ch34x-mac-os-x-driver"
      "mistertea/et"
      "one2nc/cloudlens"
      "osx-cross/arm"
      "osx-cross/avr"
      "qmk/qmk"
      "rhyeal/aws-rotate-iam-keys"
      "robscott/tap"
      "sheerun/git-squash"
      "siderolabs/tap"
      "slp/krun"
      "snyk/tap"
      "sonatype-nexus-community/nancy-tap"
      "specstoryai/tap"
      "synfinatic/aws-sso-cli"
      "thefox/brewery"
      "wagoodman/dive"
      "wallix/awless"
      "warrensbox/tap"
      "weaveworks/tap"
    ];

    brews = [
      # ── From homebrew/core ───────────────────────────────────────────────
      "act"
      "age"
      "amazon-ecs-cli"
      "ansible"
      "antigen"
      "autojump"
      "automake"
      "avro-tools"
      "aws-iam-authenticator"
      "aws-sso-cli"
      "awscli"
      "bats-core"
      "bitwarden-cli"
      "btop"
      "bundletool"
      "calicoctl"
      "cdrtools"
      "certbot"
      "chamber"
      "chezmoi"
      "cmake"
      "colima"
      "colordiff"
      "cpufetch"
      "direnv"
      "dive"
      "docutils"
      "dua-cli"
      "dust"
      "duti"
      "esphome"
      "esptool"
      "exercism"
      "ext4fuse"
      "faas-cli"
      "figlet"
      "findutils"
      "fisher"
      "fortune"
      "fx"
      "fzf"
      "geckodriver"
      "gemini-cli"
      "gh"
      "git"
      "gitleaks"
      "glances"
      "gnu-sed"
      "go-md2man"
      "gobject-introspection"
      "golangci-lint"
      "gpx"
      "gradle"
      "graphviz"
      "gum"
      "guile"
      "hive"
      "htop"
      "httrack"
      "hugo"
      "imagemagick"
      "ipcalc"
      "iperf3"
      "iproute2mac"
      "jq"
      "juju"
      "julia"
      "k6"
      "kcat"
      "knock"
      "kompose"
      "kubebuilder"
      "kubernetes-cli"
      "kyverno"
      "lazygit"
      "lftp"
      "libgit2"
      "libvirt"
      "macchina"
      "macvim"
      "maven"
      "mintoolkit"
      "mosquitto"
      "neovim"
      "nmap"
      "nuget"
      "oci-cli"
      "octant"
      "ondir"
      "opencode"
      "openvpn"
      "packer"
      "parallel"
      "podman"
      "postgresql@14"
      "protoc-gen-grpc-web"
      "pyenv-virtualenv"
      "python-tabulate"
      "python@3.11"
      "python@3.8"
      "python@3.9"
      "qemu"
      "qwen-code"
      "rbenv"
      "reattach-to-user-namespace"
      "redis"
      "repomix"
      "s3cmd"
      "selenium-server"
      "shellcheck"
      "sops"
      "sphinx-doc"
      "sshuttle"
      "starship"
      "swagger-codegen"
      "swaks"
      "swig"
      "tailwindcss"
      "tdd-guard"
      "telnet"
      "terminal-notifier"
      "terraform-docs"
      "terraform_landscape"
      "terraformer"
      "tfenv"
      "tflint"
      "thefuck"
      "tldr"
      "tmuxinator"
      "truncate"
      "typescript"
      "uv"
      "watch"
      "wget"
      "ykpers"
      "youtube-dl"
      "z"
      "zenity"
      "zig"
      "zoxide"
      "zsh"

      # ── From third-party taps ────────────────────────────────────────────
      "act3" # dhth/tap
      "avr-gcc@9" # osx-cross/avr
      "buildah" # slp/krun
      "buf" # bufbuild/buf
      "cloudlens" # one2nc/cloudlens
      "eksctl-aws-iam-authenticator" # weaveworks/tap
      "et" # mistertea/et
      "git-chglog" # git-chglog/git-chglog
      "git-squash" # sheerun/git-squash
      "granted" # common-fate/granted
      "k9s" # derailed/k9s
      "kdash" # kdash-rs/kdash
      "ks" # ksonnet/tap
      "kubecolor" # hidetatz/tap
      "kubetail" # johanhaleby/kubetail
      "nancy" # sonatype-nexus-community/nancy-tap
      "phook" # thefox/brewery
      "qmk" # qmk/qmk
      "snyk" # snyk/tap
      "specstory" # specstoryai/tap
      "sshfs-mac" # gromgit/fuse
    ];

    casks = [
      "alacritty"
      "android-platform-tools"
      "aws-vault-binary"
      "balenaetcher"
      "barrier"
      "chromedriver"
      "cmux"
      "edex-ui"
      "epichrome"
      "font-input"
      "gdisk"
      "gswitch"
      "kui"
      "lens"
      "logi-options+"
      "macfuse"
      "macvim-app"
      "microsoft-remote-desktop"
      "multipass"
      "ngrok"
      "scribus"
      "stats"
      "timemachineeditor"
      "transmit"
      "vagrant"
      "warp"
      "wch-ch34x-usb-serial-driver"
      "xbar"
      "yubico-yubikey-manager"
    ];
  };

  # ── macOS system defaults ─────────────────────────────────────────────────
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };
    dock = {
      autohide = true;
      show-recents = false;
      tilesize = 48;
    };
    finder = {
      AppleShowAllFiles = true;
      FXEnableExtensionChangeWarning = false;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
  };

  # ── User ──────────────────────────────────────────────────────────────────
  users.users.${userName} = {
    name = userName;
    home = "/Users/${userName}";
    shell = pkgs.fish;
  };

  system.stateVersion = 5;
}
