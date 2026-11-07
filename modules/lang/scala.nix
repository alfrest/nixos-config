# Scala toolchain for the alfrest user; unstable for freshness. Metals is the
# LSP and coursier the launcher.
{ ... }:

{
  flake.nixosModules.lang-scala =
    { pkgs-unstable, ... }:
    {
      home-manager.users.alfrest.home.packages = with pkgs-unstable; [
        scala
        metals
        coursier
      ];
    };
}
