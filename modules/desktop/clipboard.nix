# Wayland clipboard helpers. `wl-copy`/`wl-paste` need a running compositor,
# so this lives in `modules/desktop/` rather than with the CLI tools.
{ ... }:

{
  flake.nixosModules.clipboard =
    { pkgs, ... }:
    {
      home-manager.users.alfrest.home.packages = [ pkgs.wl-clipboard ];
    };
}
