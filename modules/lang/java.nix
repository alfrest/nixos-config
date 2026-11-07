# Java toolchain for the alfrest user.
{ ... }:

{
  flake.nixosModules.lang-java =
    { pkgs, ... }:
    {
      home-manager.users.alfrest.home.packages = with pkgs; [
        openjdk25
      ];
    };
}
