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
      vim.keymap.set('n', ' ', '<Nop>')
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

      local fzf = require 'fzf-lua'
      fzf.setup {}

      local wk = require 'which-key'
      wk.setup {}
      wk.add({ 
        {"<leader>?", function() wk.show() end, desc = "Buffer Local Keymaps (which-key)"},
	{
	  {"<leader>w", "<cmd>w<cr>", desc = "Write"},
	},
	{
	  {"gd", function() vim.lsp.buf.definition() end, desc = "Jump to definition"}
	},
	{
	  {"<leader>l", group = "LSP"},
          {"<leader>la", function() fzf.lsp_code_actions() end, desc = "Code Action"},
          {"<leader>ld", function() fzf.diagnostics_document() end, desc = "Diagnostic"},
	},
      })

      local lspconfig = require 'lspconfig'
      lspconfig.nixd.setup {}
      lspconfig.rust_analyzer.setup {}
    '';
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      which-key-nvim
      fzf-lua
    ];
  };
  config.home.packages = with pkgs; [ nixd rust-analyzer fzf ];
}
