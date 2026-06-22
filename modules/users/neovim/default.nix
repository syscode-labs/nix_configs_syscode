{ pkgs, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = !pkgs.stdenv.isDarwin;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      fd
      git
      lazygit
      ripgrep
      tree-sitter
    ];

    # Only lazy-nvim on the packpath — LazyVim is loaded exclusively
    # via its nix store path in the lazy spec below, avoiding double-loading.
    extraPlugins = with pkgs.vimPlugins; [
      lazy-nvim
    ];

    globals = {
      mapleader = " ";
      maplocalleader = "\\";
    };

    opts = {
      number = true;
      relativenumber = true;
      termguicolors = true;
      signcolumn = "yes";
    };

    extraConfigLua = ''
      require("lazy").setup({
        spec = {
          {
            dir = "${pkgs.vimPlugins.LazyVim}",
            name = "LazyVim",
            import = "lazyvim.plugins",
          },
        },
        defaults = {
          lazy = false,
          version = false,
        },
        install = {
          colorscheme = { "tokyonight", "habamax" },
        },
        checker = {
          enabled = false, -- nix pins LazyVim; auto-update checks are unnecessary
        },
        performance = {
          rtp = {
            disabled_plugins = {
              "gzip",
              "matchit",
              "matchparen",
              "netrwPlugin",
              "tarPlugin",
              "tohtml",
              "tutor",
              "zipPlugin",
            },
          },
        },
      })
    '';
  };
}
