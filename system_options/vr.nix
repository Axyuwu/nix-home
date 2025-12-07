{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.system_options.vr;
in
{
  options.system_options.vr.enable = lib.options.mkEnableOption "VR configuration";
  config = lib.mkIf cfg.enable {
    system_options.graphical.enable = true;
    quickselect.programs = {
      "ALVR" = "steam-run alvr_dashboard";
    };

    bsinstaller = {
      enable = true;
      install_path = "$HOME/.steam/steam/steamapps/common/Beat Saber/";
    };

    home.packages = (
      with pkgs;
      [
        alvr
        wlx-overlay-s
      ]
    );
  };
}
