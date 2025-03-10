{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.bsinstaller;
  install_script = pkgs.writeShellScript "bsinstall" ''
    set -e -u -o pipefail

    prefix='beatsaver://'

    path=$1

    if [[ $path != $prefix* ]]; then
      echo "Invalid url!"
      echo $1
      exit
    fi

    map_id="''${path#$prefix}"

    zip=$(mktemp)

    download_url="$(
      curl -X GET \
      -H 'accept: application/json' \
      "https://api.beatsaver.com/maps/id/$map_id" \
      | ${pkgs.jq}/bin/jq -r .versions.[0].downloadURL
    )"

    headers=$(mktemp)
    echo $download_url

    curl -X GET \
    $download_url \
    -o $zip \
    -D $headers

    filename=$(
      cat $headers \
      | grep -o -E 'filename=.*$' \
      | sed -e 's/filename=//' \
      | sed 's/\r$//'\
      | xargs basename
    )
    rm $headers

    ${pkgs.unzip}/bin/unzip -n "$zip" -d "${cfg.install_path}/Beat Saber_Data/CustomLevels/$(basename "$filename" .zip)"

    rm $zip
  '';
  run_installer = pkgs.writeShellScript "bsinstallgui" ''
    ${pkgs.kitty}/bin/kitty \
      --title "${cfg.title}" \
      -o remember_window_size=no \
      -o initial_window_width=40c \
      -o initial_window_height=24c \
      ${pkgs.writeShellScript "bsinstaller_term" ''
        ${install_script} "$1"
        if [[ $? != 0 ]]; then
          echo "Press any key to exit"
          read -n1 _name
          exit
        fi
      ''} "$1"
  '';
in
{
  options.bsinstaller = with lib; {
    enable = mkEnableOption "Beat saber asset installer";
    install_path = mkOption {
      type = types.str;
      description = "Paths beat saber is installed at";
    };
    title = mkOption {
      type = types.str;
      description = "The name of the window";
      readOnly = true;
      default = "BSInstaller";
    };
  };
  config = lib.mkIf cfg.enable {
    xdg.desktopEntries.beatsaberinstaller = {
      name = "Beatsaver";
      startupNotify = false;
      mimeType = [ "x-scheme-handler/beatsaver" ];
      exec = "${run_installer} %u";
    };
  };
}
