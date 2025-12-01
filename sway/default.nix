{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.sway;
  terminal-open =
    { title, bin }:
    pkgs.writeShellScript "terminal_open" ''
      kitty \
      --title ${lib.escapeShellArg title} \
      -o remember_window_size=no \
      -o initial_window_width=56c \
      -o initial_window_height=16c \
      ${bin}
    '';
  hiblock = pkgs.writeShellApplication {
    name = "hiblock";
    text = ''
      ( sleep 120; systemctl suspend ) &
      hibernate=$!
      swaylock
      kill -s sigkill $hibernate
    '';
  };
in
{
  options.sway = with lib; {
    enable = mkEnableOption "Sway module";
    pkg = mkOption {
      type = types.package;
      description = "Sway package to use";
      default = pkgs.swayfx;
    };
  };
  config = lib.mkIf cfg.enable {
    wayland.windowManager.sway =
      let
        left = "h";
        down = "j";
        up = "k";
        right = "l";
        modifier = "Mod4";
      in
      {
        enable = true;
        systemd.enable = true;
        config = {
          modifier = modifier;
          terminal = "kitty";
          startup = [
            {
              command = "kanshictl reload";
              always = true;
            }
            {
              command = "swaybg -i ${./wallpapers/rainbow-cat.png}";
              always = true;
            }
          ];
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
            "${modifier}+i" = "exec ${
              terminal-open {
                title = "Quickselect";
                bin = "quickselect";
              }
            }";
            "${modifier}+Shift+i" = "exec kitty";
            "${modifier}+x" = "kill";
            "${modifier}+Shift+s" = "exec slurp | grim -g - - | wl-copy";
            "${modifier}+s" = "split toggle";
            "${modifier}+d" = "focus parent";
            "${modifier}+Shift+y" = "exec hiblock";
            "${modifier}+Shift+q" = ''
              exec swaynag \
                -t warning \
                -m 'Do you really want to exit sway?' \
                -b 'Yes' 'swaymsg exit'
            '';
            "${modifier}+Shift+r" = "reload";
            "${modifier}+p" = "exec ${
              terminal-open {
                title = "Passpass";
                bin = "passpass-get";
              }
            }";
            "${modifier}+Shift+p" = "exec ${
              terminal-open {
                title = "Passpass";
                bin = "passpass-gen";
              }
            }";
            "${modifier}+c" = "exec wl-copy -c";
            "${modifier}+n" = "exec swaync-client -t";
            "XF86AudioPlay" = "exec playerctl play-pause";
            "XF86AudioMute" = "exec pamixer -t";
            "XF86AudioLowerVolume" = "exec pamixer -d 5";
            "XF86AudioRaiseVolume" = "exec pamixer -i 5";
            "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
            "XF86MonBrightnessUp" = "exec brightnessctl set 5%+";
            "XF86AudioMicMute" = "exec pamixer --default-sink -t";
          };

          /*
            seat = {
              "*" = {
                hide_cursor = "3000";
              };
            };
          */

          bars = [
            {
              mode = "dock";
              hiddenState = "hide";
              position = "bottom";
              workspaceButtons = true;
              workspaceNumbers = true;
              fonts = {
                names = [ "jetbrains mono" ];
                size = 9.0;
              };
              trayOutput = "primary";
              colors =
                let
                  mkTarget = background: text: {
                    inherit background text;
                    border = "$base";
                  };
                in
                {
                  background = "$base";
                  statusline = "$text";
                  focusedStatusline = "$text";
                  separator = "$base";
                  focusedSeparator = "$base";
                  focusedWorkspace = mkTarget "$lavender" "$crust";
                  activeWorkspace = mkTarget "$overlay0" "$text";
                  inactiveWorkspace = mkTarget "$base" "$text";
                  urgentWorkspace = mkTarget "$peach" "$crust";
                };
              statusCommand = "i3status-rs config-default.toml";
            }
          ];

          modes = { };
          colors =
            lib.attrsets.mapAttrs
              (
                _: value:
                (
                  {
                    border = "$overlay0";
                    background = "$base";
                    text = "$text";
                    indicator = "$overlay0";
                    childBorder = "$overlay0";
                  }
                  // value
                )
              )
              {
                focused = {
                  border = "$lavender";
                  childBorder = "$lavender";
                  indicator = "$lavender";
                };
                focusedInactive = { };
                unfocused = { };
                urgent = {
                  border = "$peach";
                  text = "$peach";
                  indicator = "$peach";
                  childBorder = "$peach";
                };
                placeholder = { };
              }
            // {
              background = "$base";
            };
          floating.criteria =
            let
              addIf = cond: val: if cond then [ val ] else [ ];
            in
            lib.lists.flatten [
              { "title" = "Quickselect"; }
              { "title" = "Passpass"; }
              (addIf config.bsinstaller.enable { "title" = config.bsinstaller.title; })
            ];
        };

        extraConfig = ''
          default_dim_inactive 0.1
        '';
        package = pkgs.swayfx;
        checkConfig = false;
      };
    programs.i3status-rust = {
      enable = true;
      bars.default = {
        theme = "ctp-macchiato";
        icons = "material-nf";
        blocks = lib.mkForce [
          {
            block = "notify";
            driver = "swaync";
            format = " $icon {($notification_count.eng(w:1)) |}";
            click = [
              {
                button = "left";
                action = "show";
              }
            ];
          }
          {
            block = "battery";
            format = " $icon $percentage% ";
            missing_format = "";
          }
          {
            block = "time";
            interval = 1;
            format = " $icon $timestamp.datetime(f:'%A %d/%m/%Y %T') ";
          }
        ];
      };
    };

    home.packages = [ hiblock ];

    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
        screenshot = true;
        effect-blur = "9x9";
        clock = true;
        indicator-caps-lock = true;
        indicator = true;
      };
    };

    /*
      services.swayidle = {
        enable = true;
        timeouts = [
          {
            timeout = 60;
            command = "swaymsg 'output * power off'";
            resumeCommand = "swaymsg 'output * power on'";
          }
        ];
      };
    */

    services.kanshi = {
      enable = true;
      settings = [
        {
          profile.name = "main_pc_3_monitors";
          profile.outputs =
            let
              monitor_to_pos = arg: "${builtins.toString arg.pos.x},${builtins.toString arg.pos.y}";
              monitor_to_mode =
                arg: fps:
                "${builtins.toString arg.dim.x}x${builtins.toString arg.dim.y}@${builtins.toString fps}Hz";
              monitor_1 = {
                dim = {
                  x = 1920;
                  y = 1080;
                };
                pos = {
                  x = 0;
                  y = 1440 - 1080;
                };
              };
              monitor_2 = rec {
                dim = {
                  x = 2560;
                  y = 1440;
                };
                pos = {
                  x = monitor_1.pos.x + monitor_1.dim.x;
                  y = monitor_1.pos.y + monitor_1.dim.y - dim.y;
                };
              };
              monitor_3 = rec {
                dim = {
                  x = 1920;
                  y = 1080;
                };
                pos = {
                  x = monitor_2.pos.x + monitor_2.dim.x;
                  y = monitor_2.pos.y + monitor_2.dim.y - dim.y;
                };
              };
            in
            [
              {
                criteria = "AOC 24B2W1 0x00001A5F";
                mode = monitor_to_mode monitor_1 "74.973";
                position = monitor_to_pos monitor_1;
              }
              {
                criteria = "Samsung Electric Company LC32G5xT HNATA00141";
                adaptiveSync = true;
                mode = monitor_to_mode monitor_2 144;
                position = monitor_to_pos monitor_2;
              }
              {
                criteria = "AOC 2400W LZMI3JA000258";
                mode = monitor_to_mode monitor_3 60;
                position = monitor_to_pos monitor_3;
              }
            ];
        }
      ];
    };
  };
}
