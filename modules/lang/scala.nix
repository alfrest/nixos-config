{ ... }:

{
  flake.nixosModules.lang-scala =
    { pkgs-unstable, ... }:
    {
      environment.systemPackages = [
        pkgs-unstable.scala
      ];
    };
}
