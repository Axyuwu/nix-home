# Requires jetbrains mono to be installed if the terminal_open value isn't set
{
  pkgs,
  title ? "Quickselect",
  # function returning a shell script derivation that, given a title and a binary file, opens that binary file with that title inside a terminal
  terminal_open ?
    { title, quickselect_bin }:
    pkgs.writeShellScript "terminal_open" ''
      ${pkgs.kitty}/bin/kitty \
      --title "${title}" \
      -o remember_window_size=no \
      -o initial_window_width=56c \
      -o initial_window_height=16c \
      ${quickselect_bin} "$1"
    '',
}:

rec {
  bin = terminal_open {
    inherit title;
    quickselect_bin = pkgs.writeShellScript "quickselect" ''
      $("$1"/"$(ls -A "$1" | ${pkgs.fzf}/bin/fzf)")
    '';
  };
  pkg = pkgs.writeShellScriptBin "quickselect" ''
    ${bin}
  '';
  mkconfig =
    set:
    pkgs.runCommand "quickselect_mkconfig" { } (
      pkgs.lib.lists.foldl (a: b: a + b) "mkdir $out \n" (
        pkgs.lib.attrsets.mapAttrsToList (name: value: "ln -s \"${value}\" \"$out/${name}\"\n") set
      )
    );
  inherit title;
}
