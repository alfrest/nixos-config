# Per-user media tools. Zen comes from the flake input; its binary is
# `zen-beta` (the `default` package is the beta variant, and there is no `zen`).
{ ... }:

{
  flake.nixosModules.home-media =
    { pkgs, zen-browser, ... }:
    {
      home-manager.users.alfrest.home.packages = [
        zen-browser
        pkgs.playerctl
      ];
    };
}
