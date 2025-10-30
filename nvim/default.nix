{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.nvim;
  ft-header-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "42-header.nvim";
    version = "2025-04-16";
    src = pkgs.fetchFromGitHub {
      owner = "Diogo-ss";
      repo = "42-header.nvim";
      rev = "4303be09d9615e9169661b3e5d5a98c3eecee0ff";
      hash = "sha256-7byIoFoaRag23Zej7ioL+2WjAv7Zttn1/WZrya0NZPo=";
    };
  };
in
{
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
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;
    extraLuaConfig = builtins.readFile ./init.lua;
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      which-key-nvim
      fzf-lua
      lualine-nvim
      nvim-cmp
      cmp-nvim-lsp
      barbar-nvim
      nvim-web-devicons
      luasnip
      gitsigns-nvim
      guess-indent-nvim
      lsp-format-nvim
      ft-header-nvim
    ];
  };
  config.home.packages = with pkgs; [
    nixd
    rust-analyzer
    fzf
    lua-language-server
    nixfmt-rfc-style
    fd
  ];
}
