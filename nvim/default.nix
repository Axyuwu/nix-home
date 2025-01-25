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
    extraLuaConfig = builtins.readFile ./init.lua;
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      which-key-nvim
      fzf-lua
      lualine-nvim
      nvim-cmp
      barbar-nvim
      nvim-tree-lua
      nvim-web-devicons
      luasnip
    ];
  };
  config.home.packages = with pkgs; [ nixd rust-analyzer fzf lua-language-server ];
}
