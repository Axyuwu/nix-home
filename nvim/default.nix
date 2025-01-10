{
  config,
  lib,
  pkgs,
  ... 
}:

let
  cfg = config.nvim;
in {
  options.nvim = with lib; {
    enable = mkEnableOption "Neovim module";
    package = mkOption {
      type = types.package;
      default = pkgs.neovim-unwrapped;
      description = "What neovim package to use";
    };
  };
  config.programs.neovim = lib.mkIf cfg.enable {
    enable = true;
    package = cfg.package;
    extraLuaConfig = ''
      vim.keymap.del('n', ' ')
      vim.g.mapleader = ' '
      vim.g.maplocalleader = ' '
      vim.g.have_nerd_font = true
      vim.opt.number = true
      vim.opt.mouse = 'a'
      vim.opt.clipboard = 'unnamedplus'
      vim.opt.breakindent = true
      vim.opt.undofile = true
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.signcolumn = 'yes'
      vim.opt.updatetime = 250
      vim.opt.timeoutlen = 300
      vim.opt.splitright = true
      vim.opt.splitbelow = true
      vim.opt.inccommand = 'split'
      vim.opt.cursorline = true
      vim.opt.scrolloff = 10

      require 'nvim-treesitter.configs'.setup {}

      local lspconfig = require 'lspconfig'
      lspconfig.nixd.setup {}
    '';
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      mini-nvim
    ];
  };
  config.home.packages = with pkgs; [ nixd ];
}
