{ config, pkgs, lib, ... }: 

let 
  profile_name = "axy";
  pkg_bin = pkg: file: "${pkgs.${pkg}}/bin/${file}";
  pkg_exec = pkg: pkg_bin pkg pkg;
  sway = pkgs.swayfx;
  swaymsg = pkg_bin "swayfx" "swaymsg";
  fish = pkg_exec "fish";
  kitty = pkg_exec "kitty";
  terminal = kitty;
  quickselect = import ./quickselect.nix { inherit pkgs; };
  nvim = pkg_bin "neovim" "nvim";
  firefox = pkg_exec "firefox";
  discord = pkg_exec "vesktop";
  prism = pkg_exec "prismlauncher";
  run_bg = program: pkgs.writeShellScript "run_background" "${swaymsg} exec ${program}";
  quickselect_config = quickselect.mkconfig {
    "Kitty" = run_bg kitty;
    "Steam" = run_bg "steam";
    "Neovim" = run_bg "${kitty} ${nvim}";
    "Firefox" = run_bg firefox;
    "Discord" = run_bg discord;
    "Prism Launcher" = run_bg prism;
  };
  steam = pkgs.steam.override {
    extraPkgs = p: ([ p.jetbrains-mono ]);
  };
in {
  home.username = profile_name;
  home.homeDirectory = "/home/${profile_name}";

  home.stateVersion = "24.11";

  home.sessionVariables = {
    DEFAULT_BROWSER = firefox;
  };

  home.packages = (with pkgs; [
    wl-clipboard
    slurp
    grim
    vesktop
    rustc
    cargo
    neofetch
    htop
    zip
    unzip
    fzf
    wev
    playerctl
    jetbrains-mono
    xdg-utils
    prismlauncher
  ]) ++ [ steam steam.run quickselect.pkg ];

  nixpkgs.config = {
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg)[
      "steam"
      "steam-unwrapped"
      "steam-run"
    ];
  };

  wayland.windowManager.sway = let
    left = "h";
    down = "j";
    up = "k";
    right = "l";
    terminal_open = arg: "exec ${terminal} ${arg}";
    modifier = "Mod4";
    copy = pkg_bin "wl-clipboard" "wl-copy";
    paste = pkg_bin "wl-clipboard" "wl-paste";
  in {
    enable = true;
    systemd.enable = true;
    config = {
      modifier = modifier;
      terminal = terminal;
      startup = [
        { command = firefox; }
        { command = discord; }
	#{ command = "steam"; }
	{ command = "${pkg_bin "kanshi" "kanshictl"} reload"; always = true; }
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
        "${modifier}+i" = "exec ${quickselect.bin} ${quickselect_config}";
        "${modifier}+Shift+i" = "exec ${terminal}";
        "${modifier}+x" = "kill";
        "${modifier}+s" = "layout toggle split";
        "${modifier}+Shift+s" = "exec ${pkg_exec "slurp"} | ${pkg_exec "grim"} -g - - | ${copy}";
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

  fonts.fontconfig.enable = true;

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

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "Axy";
      userEmail = "gilliardmarthey.axel@gmail.com";
    };
    fish = {
      enable = true;
    };
    neovim = {
      enable = true;
    };
    kitty = {
      enable = true;
      shellIntegration.enableFishIntegration = true;
      font = {
        name = "jetbrains mono";
	package = pkgs.jetbrains-mono;
	size = 12;
      };
      settings = {
        shell = "fish";
      };
    };
    firefox = {
      enable = true;
      profiles.${profile_name} = {
        isDefault = true;
      };
    };
  };
}
