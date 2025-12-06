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
      texliveMedium
    ];
    home.file.".latexmkrc".text = ''
      $pdf_previewer = 'start evince';
    '';
    nvim.enable = true;
    programs = {
      gcc.enable = true;
    };
  };
}
