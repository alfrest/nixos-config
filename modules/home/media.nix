# Media / browser packages, from the tail of the Arch `niri` role.
#
# The old machine installed the Zen browser (AUR) and `playerctl`, and bound
# `Mod+B` to the browser and the media keys to `playerctl`. Both are per-user
# tools, so they go into the Home Manager profile like the rest of P3.
#
# `playerctl` is a normal nixpkgs package. Zen is not in nixpkgs and comes from
# the community flake declared in flake.nix; it reaches modules as the
# `zen-browser` argument (see the `specialArgs` in modules/hosts/vm/default.nix),
# pinned to that flake's `packages.<system>.default`. The same derivation is
# interpolated by name in the niri config, so the attribute name must not drift.
#
# Note the binary name: the flake's `default` is its `beta` variant and the
# package ships `bin/zen-beta` (package `zen-beta-<version>`). There is no
# `bin/zen`, so both the command and the niri `Mod+B` bind use `zen-beta`.
#
# Not migrated: nothing here touches the vault. The Zen profile data is left to
# the user (no `user.js`, no sync setup), which mirrors the old role, where the
# browser was only installed.
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
