# Java toolchain for the alfrest user.
{ ... }:

{
  flake.nixosModules.java =
    { pkgs, ... }:
    {
      home-manager.users.alfrest.home.packages = with pkgs; [
        openjdk25
      ];
    };
}
