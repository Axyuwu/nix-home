{
  pkgs,
  lib,
  ...
}:

{
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
}
