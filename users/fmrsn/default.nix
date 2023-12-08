{pkgs, ...}: let
  inherit (pkgs.stdenv) isDarwin;
in {
  users.users = let
    homeDir =
      if isDarwin
      then "/Users"
      else "/home";
    name = "fmrsn";
  in {
    "${name}" = {
      inherit name;
      home = "${homeDir}/${name}";
    };
  };
}
