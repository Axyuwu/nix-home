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
  config = lib.mkIf cfg.enable {
    programs.neovim = { enable = true; package = cfg.package; };
  };
}
