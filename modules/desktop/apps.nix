# Per-user graphical applications: browser, media players and viewers.
# Zen comes from the flake input; its binary is `zen-beta` (the `default`
# package is the beta variant, and there is no `zen`).
#
# `playerctl` is here rather than in `modules/tools/cli-tools.nix` because its
# only consumer is the niri media-key bindings, which need a running session.
{ ... }:

{
  flake.nixosModules.apps =
    { pkgs, zen-browser, ... }:
    {
      # Spotify and Discord are unfree. Named allow-list rather than a
      # predicate so it merges with the predicate other modules (e.g.
      # `nvidia`) set.
      nixpkgs.config.allowUnfreePackages = [
        "spotify"
        "discord"
      ];

      home-manager.users.alfrest.home.packages = with pkgs; [
        zen-browser
        playerctl
        spotify
        discord
        nautilus
        mpv
        papers
        loupe
        qbittorrent
      ];
    };
}
