{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.system_options.graphical;
in
{
  options.system_options.graphical.enable = lib.options.mkEnableOption "Graphical configuration";
  config = lib.mkIf cfg.enable {
    system_options.minimal.enable = true;
    home.sessionVariables = {
      DEFAULT_BROWSER = "firefox";
    };

    sway.enable = true;

    catppuccin = {
      enable = true;
      flavor = "macchiato";
    };

    quickselect = {
      enable = true;
      programs = {
        "Kitty" = "kitty";
        "Neovim" = "kitty nvim";
        "Firefox" = "firefox";
        "Discord" = "vesktop";
        "Gimp" = "gimp";
        "Pavucontrol" = "pavucontrol";
        "Droidcam" = "droidcam";
        "Telegram" = "Telegram";
        "Krita" = "krita";
        "Calcurse" = "kitty calcurse";
        "Steam" = "steam";
        "Prism Launcher" = "prismlauncher";
        "OBS" = "obs";
        "Kwave" = "kwave";
        "GPU Screen Recorder" = "gpu-screen-recorder-gtk";
        "Thunderbird" = "thunderbird";
      };
    };

    passpass.graphical = true;

    home.packages =
      (with pkgs; [
        wl-clipboard
        slurp
        grim
        vesktop
        wev
        playerctl
        jetbrains-mono
        xdg-utils
        swaybg
        pamixer
        brightnessctl
        prismlauncher
        protontricks
        rustc
        cargo
        gcc
        gimp
        pulseaudio
        pavucontrol
        droidcam
        android-tools
        v4l-utils
        ffmpeg
        mpv
        wineWowPackages.stable
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-extra
        noto-fonts-color-emoji
        telegram-desktop
        krita
        slides
        calcurse
        kdePackages.kwave
        gpu-screen-recorder
        gpu-screen-recorder-gtk
        thunderbird
        feh
        yt-dlp
        dconf
        libnotify
      ])
      ++ (
        let
          steam = pkgs.steam.override {
            extraPkgs = p: [ p.jetbrains-mono ];
          };
        in
        [
          steam
          steam.run
        ]
      );

    nixpkgs.config = {
      allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "steam"
          "steam-unwrapped"
          "steam-run"
        ];
    };

    fonts.fontconfig.enable = true;

    gtk = {
      enable = true;
    };

    services = {
      swaync = {
        enable = true;
      };
    };

    programs = {
      kitty = {
        enable = true;
        font = {
          name = "Jetbrains Mono NL";
          package = pkgs.jetbrains-mono;
          size = 12;
        };
        settings = {
          shell = "bash";
          clear_all_shortcuts = "yes";
          kitty_mod = "ctrl+shift";
        };
        keybindings = {
          "f1" = "launch --cwd=current --type=os-window --copy-env";
          "kitty_mod+c" = "copy_to_clipboard";
          "kitty_mod+v" = "paste_from_clipboard";
        };
      };
      firefox = {
        enable = true;
        profiles.${config.home.username} = {
          isDefault = true;
          search = {
            force = true;
            default = "ddg";
            privateDefault = "ddg";
          };
          extensions = {
            force = true;
            packages = with pkgs.nur.repos.rycee.firefox-addons; [
              ublock-origin
              privacy-badger
              sponsorblock
              youtube-shorts-block
            ];
          };
        };
      };
      obs-studio = {
        enable = true;
      };
    };
  };
}
