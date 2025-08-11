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
        ruthenium = {
          system = "x86_64-linux";
          options = {
            minimal = true;
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
            { system_options = builtins.mapAttrs (_: enable: { inherit enable; }) options; }
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
