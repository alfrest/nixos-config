# Per-user media tools. Zen comes from the flake input; its binary is
# `zen-beta` (the `default` package is the beta variant, and there is no `zen`).
{ ... }:

{
  flake.nixosModules.home-media =
    { pkgs, zen-browser, ... }:
    {
      # Spotify is unfree. Named allow-list rather than a predicate so it
      # merges with the predicate other modules (e.g. `desktop-nvidia`) set.
      nixpkgs.config.allowUnfreePackages = [ "spotify" ];

      home-manager.users.alfrest.home.packages = [
        zen-browser
        pkgs.playerctl
        pkgs.spotify
      ];
    };
}
