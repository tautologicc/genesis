{
  self,
  inputs,
  config,
  flake-parts-lib,
  withSystem,
  ...
}: let
  # TODO(fmrsn): Use this version as the global lib argument.
  lib = nixpkgs.lib.extend (import ./lib.nix);

  cfg = config.genesis;

  inherit
    (inputs)
    home-manager
    nix-darwin
    nixpkgs
    ;

  inherit (lib) types;

  inherit
    (flake-parts-lib)
    mkPerSystemOption
    ;

  mkHost = hostName: args @ {system, ...}: let
    pkgs = withSystem system ({pkgs, ...}: pkgs);
    rosettaPkgs = import pkgs {system = "x86_64-darwin";};

    inherit (pkgs.stdenv) isDarwin isLinux;

    mkSystem =
      if isDarwin
      then nix-darwin.lib.darwinSystem
      else nixpkgs.lib.nixosSystem;

    commonModules = [
      ./modules
      {
        system.configurationRevision = lib.mkIf (self ? rev) self.rev;
        networking = {inherit hostName;};
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }
    ];

    nixosModules = lib.optionals isLinux [
      home-manager.nixosModules.home-manager
    ];

    darwinModules = lib.optionals isDarwin [
      home-manager.darwinModules.home-manager
    ];

    args' = lib.recursiveMerge [
      args
      rec {
        specialArgs = {inherit rosettaPkgs;};
        modules =
          [{home-manager.extraSpecialArgs = specialArgs;}]
          ++ commonModules
          ++ nixosModules
          ++ darwinModules;
      }
    ];
  in rec {
    name =
      if isDarwin
      then "darwinConfigurations-${hostName}"
      else hostName;
    value = lib.recursiveUpdate (mkSystem args') (
      lib.optionalAttrs isDarwin {
        # NOTE(fmrsn): Set this attribute to satisfy `nix flake check`.
        config.system.build.toplevel = self.nixosConfigurations.${name}.system;
      }
    );
  };
in {
  # TODO(fmrsn): Write documentation.
  options.genesis.hosts = lib.mkOption {
    # TODO(fmrsn): Use a more specific type?
    type = types.lazyAttrsOf types.anything;
  };

  options.perSystem = mkPerSystemOption {
    # NOTE(fmrsn): Make darwinConfigurations and homeConfigurations visible to
    # darwin-rebuild and home-manager, respectively.
    #
    # TODO(fmrsn): Add an explanation on why we do this.
    legacyPackages = lib.genAttrs ["darwinConfigurations" "homeConfigurations"] (
      output:
        lib.pipe self.nixosConfigurations [
          (lib.filterAttrs (attr: _: lib.hasPrefix "${output}-" attr))
          (lib.mapAttrs' (attr: lib.nameValuePair (lib.removePrefix "${output}-" attr)))
        ]
    );
  };

  config.flake.nixosConfigurations = lib.mapAttrs' mkHost cfg.hosts;
}
