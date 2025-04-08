{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.quickselect;
in
{
  options.quickselect = with lib; {
    enable = mkEnableOption "Quickselect";
    programs = mkOption {
      type = types.attrsOf types.str;
      description = "Attribute set defininig the programs quickselect will propose, by default";
      default = { };
    };
  };
  config = lib.mkIf cfg.enable {
    home.packages = [
      (pkgs.writeShellScriptBin "quickselect" ''
        set -e -u -o pipefail

        if [[ $# == 0 ]]; then
          DIR=$HOME/.config/quickselect/programs
        else
          DIR=$1
        fi

        PROGRAM="$(ls -A $DIR | ${pkgs.fzf}/bin/fzf)"
        ${pkgs.swayfx}/bin/swaymsg exec "$DIR/$PROGRAM"
      '')
    ];
    home.file.".config/quickselect/programs".source = pkgs.runCommand "quickselect_mkconfig" { } ''
      mkdir $out
      ${
        (lib.strings.concatStringsSep "\n" (
          lib.attrsets.mapAttrsToList (name: value: ''
            ln -s ${lib.escapeShellArg (pkgs.writeShellScript name value)} \
              $out/${lib.escapeShellArg name}
          '') cfg.programs
        ))
      }
    '';
  };
}
