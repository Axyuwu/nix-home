{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.system_options.minimal;
  profile_name = "axy";
in
{
  options.system_options.minimal.enable = lib.options.mkEnableOption "Minimal configuration";
  config = lib.mkIf cfg.enable {
    home.username = profile_name;
    home.homeDirectory = "/home/${profile_name}";
    home.stateVersion = "24.11";

    home.packages = with pkgs; [
      neofetch
      htop
      zip
      unzip
      unrar-free
      p7zip
      bashmount
      jq
      age
      xxd
      bc
      gcr
      gnumake
      norminette
    ];

    passpass.enable = true;

    nvim.enable = true;

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

    services.gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-curses;
    };

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
      bat.enable = true;
      gpg.enable = true;
    };
  };
}
