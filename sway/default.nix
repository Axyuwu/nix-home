{ config, pkgs, lib, ... }: 

let 
  cfg = config.sway;
  pkg_bin = pkg: file: "${pkgs.${pkg}}/bin/${file}";
  pkg_exec = pkg: pkg_bin pkg pkg;
  quickselect = import ../quickselect.nix { inherit pkgs; };
  run_bg = program: pkgs.writeShellScript "run_background" "${pkg_bin "swayfx" "swaymsg"} exec ${program}";
  quickselect_config = quickselect.mkconfig (lib.attrsets.mapAttrs (_name: value: run_bg value) cfg.quickselect_config);
in {
  options.sway = with lib; {
    enable = mkEnableOption "Sway module";
    quickselect_config = mkOption {
      type = types.attrsOf types.str;
      description = "Attribute set defininig quickselect options for the keybind";
      default = {};
    }; 
    startup = mkOption {
      type = types.listOf types.str;
      description = "List of commands to run on startup";
      default = [];
    };
    terminal = mkOption {
      type = types.path;
      description = "Terminal used";
    };
  }; 
  config = lib.mkIf cfg.enable { 
    wayland.windowManager.sway = let
      cfg = config.sway;
      left = "h";
      down = "j";
      up = "k";
      right = "l";
      modifier = "Mod4";
    in {
      enable = true;
      systemd.enable = true;
      config = {
        modifier = modifier;
        terminal = "${cfg.terminal}";
        startup = [
          { command = "${pkg_bin "kanshi" "kanshictl"} reload"; always = true; }
	  { command = "${pkg_exec "swaybg"} -i ${ ./wallpapers/rainbow-cat.png }"; always = true; }
        ] ++ (builtins.map (e: { command = e; }) cfg.startup);
        input = { 
          "type:keyboard" = {
            xkb_layout = "fr";
          };
        };
        keybindings = {
          "${modifier}+${left}" = "focus left";
          "${modifier}+${down}" = "focus down";
          "${modifier}+${up}" = "focus up";
          "${modifier}+${right}" = "focus right";
          "${modifier}+Shift+${left}" = "move left";
          "${modifier}+Shift+${down}" = "move down";
          "${modifier}+Shift+${up}" = "move up";
          "${modifier}+Shift+${right}" = "move right";
          "${modifier}+Control+${left}" = "resize shrink width 10 px";
          "${modifier}+Control+${down}" = "resize shrink height 10 px";
          "${modifier}+Control+${up}" = "resize grow height 10 px";
          "${modifier}+Control+${right}" = "resize grow width 10 px";
          "${modifier}+space" = "focus mode_toggle";
          "${modifier}+f" = "fullscreen toggle";
          "${modifier}+i" = "exec ${quickselect.bin} ${quickselect_config}";
          "${modifier}+Shift+i" = "exec ${cfg.terminal}";
          "${modifier}+x" = "kill";
          "${modifier}+s" = "layout toggle split";
          "${modifier}+Shift+s" = "exec ${pkg_exec "slurp"} | ${pkg_exec "grim"} -g - - | ${pkg_bin "wl-clipboard" "wl-copy"}";
          "${modifier}+b" = "layout split horizontal";
          "${modifier}+v" = "layout split vertical";
          "${modifier}+Shift+q" = "exec swaynag -t warning -m 'Do you really want to exit sway?' -b 'Yes' 'swaymsg exit'";
          "${modifier}+Shift+r" = "reload";
      	  "XF86AudioPlay" = "exec ${pkg_exec "playerctl"} play-pause";
        };
        modes = {};
      };

      extraConfig = ''
        for_window [title = ${quickselect.title}] floating enable
        default_dim_inactive 0.2
      '';
      package = pkgs.swayfx;
      checkConfig = false;
    };

    services.kanshi = {
      enable = true;
      settings = [
        {
          profile.name = "integrated_graphics";
          profile.outputs = let 
	    monitor_to_pos = arg: "${builtins.toString arg.pos.x},${builtins.toString arg.pos.y}";
	    monitor_to_mode = arg: fps: "${builtins.toString arg.dim.x}x${builtins.toString arg.dim.y}@${builtins.toString fps}Hz";
            monitor_1 = { 
	      dim = { 
	        x = 2560; 
	        y = 1440; 
	      }; 
	      pos = {
	        x = 0;
	        y = 0;
	      };
	    };
	    monitor_2 = rec {
	      dim = { 
	        x = 1920; 
	        y = 1080; 
	      }; 
	      pos = {
	        x = monitor_1.pos.x + monitor_1.dim.x;
	        y = monitor_1.pos.y + monitor_1.dim.y - dim.y;
	      };
	    };
	  in [
            {
	      criteria = "DP-2";
	      adaptiveSync = true;
	      mode = monitor_to_mode monitor_1 144;
	      position = monitor_to_pos monitor_1;
	    }
            {
	      criteria = "HDMI-A-1";
	      mode = monitor_to_mode monitor_2 60;
	      position = monitor_to_pos monitor_2;
	    }
	  ];
        }
      ];
    };
  };
}