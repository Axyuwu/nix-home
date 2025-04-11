{
  description = "Axy home manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nur,
      nixpkgs,
      home-manager,
      catppuccin,
      ...
    }:
    let
      configs = {
        helium = {
          system = "x86_64-linux";
          options = {
            minimal = true;
            graphical = true;
            vr = true;
          };
        };
        neon = {
          system = "x86_64-linux";
          options = {
            minimal = true;
            graphical = true;
          };
        };
      };
      pkgs = {
        "x86_64-linux" = import nixpkgs {
          system = "x86_64-linux";
          overlays = [ nur.overlays.default ];
        };
      };
    in
    {
      formatter."x86_64-linux" = pkgs."x86_64-linux".nixfmt-rfc-style;
      homeConfigurations = builtins.mapAttrs (
        name:
        config@{ system, options, ... }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs.${system};
          modules = [
            {
              system_options = builtins.mapAttrs (_: enable: { inherit enable; }) options;
            }
            ./system_options
            catppuccin.homeManagerModules.catppuccin
            ./sway
            ./nvim
            ./bash
            ./bsinstaller.nix
            ./passpass
            ./quickselect.nix
          ];
        }
      ) configs;
    };
}
