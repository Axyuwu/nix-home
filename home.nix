{
  config,
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
  home.username = profile_name;
  home.homeDirectory = "/home/${profile_name}";
  home.stateVersion = "24.11";

  home.sessionVariables = {
    DEFAULT_BROWSER = pkg_exec "firefox";
  };

  imports = [
    ./sway
    ./nvim
    ./bash
    ./bsinstaller.nix
  ];

  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };

  sway = {
    enable = true;
    quickselect_config = {
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
    };
    startup = [
      "firefox"
      "vesktop"
    ];
    terminal = "kitty";
  };

  nvim = {
    enable = true;
  };

  blesh.enable = true;
  bash = {
    enable = true;
    prompt = {
      hostname.enable = true;
      nix.enable = true;
      pwd.enable = true;
      git.enable = true;
    };
    nix_shell_preserve_prompt = true;
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
      neofetch
      htop
      zip
      unzip
      wev
      playerctl
      jetbrains-mono
      xdg-utils
      prismlauncher
      swaybg
      protontricks
      unp
      unrar-free
      p7zip
      pamixer
      #rustc
      #cargo
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
      flatpak
      wineWowPackages.stable
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-extra
      noto-fonts-color-emoji
      wlx-overlay-s
      telegram-desktop
      bashmount
      jq
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
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "Axy";
      userEmail = "gilliardmarthey.axel@gmail.com";
    };
    fzf.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = true;
      config.global = {
        strict_env = true;
        disable_stdin = true;
      };
    };
    tmux = {
      enable = true;
    };
    kitty = {
      enable = true;
      shellIntegration.enableFishIntegration = true;
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
      };
    };
  };
}
