{
  pkgs,
  lib,
  ...
}:

let
  profile_name = "axy";
  pkg_bin = pkg: file: "${pkgs.${pkg}}/bin/${file}";
  pkg_exec = pkg: pkg_bin pkg pkg;
  steam = pkgs.steam.override {
    extraPkgs = p: [ p.jetbrains-mono ];
  };
in
{
  home.sessionVariables = {
    DEFAULT_BROWSER = pkg_exec "firefox";
  };

  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };

  sway = {
    enable = true;
    terminal = "kitty";
  };

  quickselect = {
    enable = true;
    programs = {
      "Kitty" = "kitty";
      "Steam" = "steam";
      "Neovim" = "kitty nvim";
      "Firefox" = "firefox";
      "Discord" = "vesktop";
      "Prism Launcher" = "prismlauncher";
      "Gimp" = "gimp";
      "Pavucontrol" = "pavucontrol";
      "Droidcam" = "droidcam";
      "ALVR" = "steam-run alvr_dashboard";
      "Telegram" = "telegram-desktop";
      "Krita" = "krita";
      "Calcurse" = "kitty calcurse";
    };
  };

  bsinstaller = {
    enable = true;
    install_path = "$HOME/.steam/steam/steamapps/common/Beat Saber/";
  };

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
      prismlauncher
      swaybg
      protontricks
      pamixer
      rustc
      cargo
      gcc
      gimp
      pulseaudio
      pavucontrol
      alvr
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
      wlx-overlay-s
      telegram-desktop
      krita
      slides
      calcurse
    ])
    ++ [
      steam
      steam.run
    ];

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
      profiles.${profile_name} = {
        isDefault = true;
        extensions = {
          packages = with pkgs.nur.repos.rycee.firefox-addons; [
            ublock-origin
            privacy-badger
            sponsorblock
          ];
        };
      };
    };
  };
}
