{ config, pkgs, lib, ... }: 

let 
  profile_name = "axy";
  pkg_bin = pkg: file: "${pkgs.${pkg}}/bin/${file}";
  pkg_exec = pkg: pkg_bin pkg pkg;
  quickselect = import ./quickselect.nix { inherit pkgs; };
  steam = pkgs.steam.override {
    extraPkgs = p: [ p.jetbrains-mono ];
  };
  rustc = pkgs.rustc;
  cargo = pkgs.cargo;
in {
  home.username = profile_name;
  home.homeDirectory = "/home/${profile_name}";
  home.stateVersion = "24.11";

  home.sessionVariables = {
    DEFAULT_BROWSER = pkg_exec "firefox";
  };

  imports = [ 
    ./sway
    ./nvim
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

  home.packages = (with pkgs; [
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
    nexusmods-app
  ]) ++ [ steam steam.run quickselect.pkg rustc cargo ];

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
    fzf.enable = true;
    fish.enable = true;
    bash.enable = true;
    zsh.enable = true;
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
