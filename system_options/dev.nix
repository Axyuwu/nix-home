{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.system_options.dev;
in
{
  options.system_options.dev.enable = lib.options.mkEnableOption "Dev configuration";
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      rust-bin.stable.latest.default
      lldb
      gdb
      nasm
      gnumake
      norminette
    ];
    nvim.enable = true;
    programs = {
      gcc.enable = true;
    };
  };
}
