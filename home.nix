{ config, pkgs, lib, ... }: 

let 
  profile_name = "axy";
  pkg_bin = pkg: file: "${pkgs.${pkg}}/bin/${file}";
  pkg_exec = pkg: pkg_bin pkg pkg;
  quickselect = import ./quickselect.nix { inherit pkgs; };
  steam = pkgs.steam.override {
    extraPkgs = p: ([ p.jetbrains-mono ]);
  };
  kitty = pkg_exec "kitty";
  nvim = pkg_bin "neovim" "nvim";
  firefox = pkg_exec "firefox";
  discord = pkg_exec "vesktop";
  prism_launcher = pkg_exec "prismlauncher";
in {
  home.username = profile_name;
  home.homeDirectory = "/home/${profile_name}";

  home.stateVersion = "24.11";

  home.sessionVariables = {
    DEFAULT_BROWSER = pkg_exec "firefox";
  };

  imports = [ 
    ./sway.nix
  ];

  sway = {
    enable = true;
    quickselect_config = {
      "Kitty" = pkg_exec kitty;
      "Steam" = "steam";
      "Neovim" = "${kitty} ${nvim}";
      "Firefox" = firefox;
      "Discord" = discord;
      "Prism Launcher" = prism_launcher;
    };
    startup = [
      firefox
      discord
    ];
    terminal = kitty;
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

  fonts.fontconfig.enable = true;

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
