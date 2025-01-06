# Requires jetbrains mono to be installed if the terminal_open value isn't set
{
  pkgs ? import <nixpkgs> { },
  title ? "Quickselect",
  # function returning a shell script derivation that, given a title and a binary file, opens that binary file with that title inside a terminal
  terminal_open ? { title, quickselect_bin }: let 
    term_config = builtins.toFile "quickselect_kitty_term_config" ''
      font_family jetbrains mono
      font_size 12

      remember_window_size no
      initial_window_width 56c
      initial_window_height 16c
    '';
  in pkgs.writeShellScript "terminal_open" ''
    ${pkgs.kitty}/bin/kitty \
    --title "${title}" \
    --config ${term_config} \
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
  mkconfig = set:
    pkgs.runCommand "quickselect_mkconfig" {} (
      pkgs.lib.lists.foldl
        (a: b: a + b)
	"mkdir $out \n"
        (
	  pkgs.lib.attrsets.mapAttrsToList
            (name: value: "ln -s \"${value}\" \"$out/${name}\"\n")
	    set
        )
    );
  inherit title;
}


