{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.system_options.dev;
  python-install = with pkgs.python3Packages; [
    pkgs.python3
    flake8
    virtualenv
    pip
    mypy
  ];
in
{
  options.system_options.dev.enable = lib.options.mkEnableOption "Dev configuration";
  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        rust-bin.stable.latest.default
        lldb
        gdb
        nasm
        gnumake
        norminette
        texliveMedium
        poppler-utils
      ]
      ++ python-install;
    home.file.".latexmkrc".text = ''
      $pdf_previewer = 'start evince';
    '';
    nvim.enable = true;
    programs = {
      gcc.enable = true;
      gemini-cli.enable = true; # i don't like llms but this is handy sometimes
    };
  };
}
