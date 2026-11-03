{ ... }:

{
  flake.nixosModules.lang-java =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        openjdk25
      ];
    };
}
