{ ... }:

{
  flake.nixosModules.lang-scala =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        scala
      ];
    };
}
