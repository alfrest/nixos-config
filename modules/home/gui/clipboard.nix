# Wayland clipboard helpers. `wl-copy`/`wl-paste` need a running compositor,
# so this belongs with the GUI modules rather than the common CLI tools.
{ ... }:

{
  flake.nixosModules.home-clipboard =
    { pkgs, ... }:
    {
      home-manager.users.alfrest.home.packages = [ pkgs.wl-clipboard ];
    };
}
