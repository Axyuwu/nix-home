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
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nur,
      nixpkgs,
      home-manager,
      catppuccin,
      flake-utils,
      rust-overlay,
      ...
    }:
    let
      configs = {
        helium = {
          system = "x86_64-linux";
          options = {

            minimal.enable = true;
            graphical.enable = true;
            vr.enable = true;
          };
        };
        neon = {
          system = "x86_64-linux";
          options = {
            minimal.enable = true;
            graphical.enable = true;
          };
        };
        ruthenium = {
          system = "x86_64-linux";
          options = {
            minimal.enable = true;
            ssh_trusted = false;
          };
        };
        ruthenium-agilliar = {
          system = "x86_64-linux";
          options = {
            minimal.enable = true;
            profile_name = "agilliar";
            ssh_trusted = false;
          };
        };
      };
      pkgs =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ nur.overlays.default ];
        };
    in
    (flake-utils.lib.eachDefaultSystem (system: {
      formatter = pkgs.legacyPackages.${system}.nixfmt-rfc-style;
    }))
    // {
      homeConfigurations = builtins.mapAttrs (
        name:
        { system, options }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs system;
          modules = [
            { nixpkgs.overlays = [ rust-overlay.overlays.default ]; }
            {
              system_options = options // {
                flake_output_name = name;
              };
            }
            ./system_options
            catppuccin.homeModules.catppuccin
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
