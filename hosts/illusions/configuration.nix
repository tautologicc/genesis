{pkgs, ...}: {
  nix.package = pkgs.nixVersions.stable;
  nix.settings = {
    extra-experimental-features = "nix-command flakes repl-flake";
    extra-nix-path = "nixpkgs=flake:nixpkgs";
    max-jobs = "auto";
  };

  nix.useDaemon = true;
  services.nix-daemon.enable = true;

  # NOTE(fmrsn): Used for backwards compatibility. Read the changelog before changing:
  #
  #     $ darwin-rebuild changelog
  #
  system.stateVersion = 4;
}
