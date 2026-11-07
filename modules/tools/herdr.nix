# herdr: unstable package plus its config, linked out-of-store so editing the
# repo file changes it without a rebuild (the path must be absolute: inside a
# flake `./files/...` resolves to a read-only store copy).
{ ... }:

{
  flake.nixosModules.herdr =
    { config, pkgs-unstable, ... }:
    let
      home = config.home-manager.users.alfrest.home.homeDirectory;
    in
    {
      home-manager.users.alfrest = {
        home.packages = [ pkgs-unstable.herdr ];

        xdg.configFile."herdr/config.toml".source =
          config.home-manager.users.alfrest.lib.file.mkOutOfStoreSymlink
            "${home}/nixos-config/modules/files/herdr/config.toml";
      };
    };
}
