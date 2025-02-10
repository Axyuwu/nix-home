{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.blesh;
in
{
  options.blesh = with lib; {
    enable = mkEnableOption "Enable ble.sh for bash";
  };
  config.programs.bash = lib.mkIf cfg.enable {
    initExtra = lib.mkOrder 1501 ''
      source ${pkgs.blesh}/share/blesh/ble.sh
    '';
  };
}
