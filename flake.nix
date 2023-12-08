{
  description = "Welcome to my house...";

  inputs = {
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} (
      let
        flakeModule = import ./flake-module.nix;
      in {
        imports = [
          inputs.devshell.flakeModule
          inputs.treefmt-nix.flakeModule

          flakeModule
        ];

        genesis.hosts = {
          illusions = {
            system = "aarch64-darwin";
            modules = [./hosts/illusions ./users/fmrsn];
          };
        };

        systems = ["aarch64-darwin"];

        perSystem = {
          inputs',
          config,
          system,
          ...
        }: {
          treefmt.config = {
            projectRootFile = ./flake.nix;
            programs.alejandra.enable = true;
          };

          devshells.default = {
            packagesFrom = [
              config.treefmt.build.devShell
            ];
            packages = [
              inputs'.nix-darwin.packages.darwin-rebuild
            ];
          };
        };
      }
    );
}
