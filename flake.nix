{
  description = "Axy home manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
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
      nixpkgs-stable,
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
            dev.enable = true;
            vr.enable = true;
          };
        };
        neon = {
          system = "x86_64-linux";
          options = {
            minimal.enable = true;
            dev.enable = true;
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
            dev.enable = true;
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
      pkgs-stable = system: import nixpkgs-stable { inherit system; };
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
          extraSpecialArgs = {
            nixpkgs-stable = pkgs-stable system;
          };
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
