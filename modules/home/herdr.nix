# herdr configuration, ported from the Arch `herdr` role.
#
# The role created `~/.config/herdr` and symlinked `config.toml` into it. Here
# the same file is vendored verbatim under `files/herdr/config.toml` and linked
# by Home Manager — as an **out-of-store** symlink to the live checkout, so
# editing the repo file changes herdr's config immediately (no rebuild, no
# read-only store copy). The file is copied unchanged on purpose: its comments
# record which herdr token is a foreground vs a background (measured from a
# rendered frame), and that knowledge is not recoverable from the values alone.
#
# Why the path is spelled out: inside a flake, `./files/...` resolves to the
# read-only copy in `/nix/store`, which would defeat `mkOutOfStoreSymlink`.
# The link therefore points at `<homeDirectory>/nixos-config/...`, i.e. this
# checkout. Moving the repo would require updating this path.
#
# `files/` contains no `.nix` files, so `import-tree` does not descend into it.
#
# The `herdr` package itself stays in modules/system/packages.nix
# (`pkgs-unstable.herdr`). Installing it here as well would pull a second copy
# from stable `pkgs` and end up with two different store paths; moving it to the
# per-user profile is a P15 cleanup decision, not part of this phase.
{ ... }:

{
  flake.nixosModules.home-herdr =
    { config, ... }:
    let
      home = config.home-manager.users.alfrest.home.homeDirectory;
    in
    {
      home-manager.users.alfrest.xdg.configFile."herdr/config.toml".source =
        config.home-manager.users.alfrest.lib.file.mkOutOfStoreSymlink
          "${home}/nixos-config/modules/home/files/herdr/config.toml";
    };
}
