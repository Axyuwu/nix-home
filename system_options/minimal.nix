{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.system_options.minimal;
  profile_name = config.system_options.profile_name;
  repo_uri = "github:Axyuwu/nix-home";
  flake_output_name = config.system_options.flake_output_name;
  homeupdate = pkgs.writeShellApplication {
    name = "homeupdate";
    text = ''
      home-manager switch --flake ${repo_uri}#${flake_output_name}
    '';
  };
in
{
  options.system_options.profile_name = lib.options.mkOption {
    default = "axy";
    type = lib.types.str;
  };
  options.system_options.flake_output_name = lib.options.mkOption {
    type = lib.types.str;
  };
  options.system_options.ssh_trusted = lib.options.mkOption {
    default = true;
    type = lib.types.bool;
  };
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
      homeupdate
      lldb
      gdb
      nasm
      clang
    ];

    passpass.enable = config.system_options.ssh_trusted;

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
      gcc.enable = true;
    };
  };
}
