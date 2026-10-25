# herdr config, linked out-of-store so editing the repo file changes it without
# a rebuild. The path must be absolute: inside a flake `./files/...` resolves to
# a read-only store copy.
#
# The `herdr` package stays in modules/system/packages.nix (`pkgs-unstable`);
# only the config is per-user.
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
