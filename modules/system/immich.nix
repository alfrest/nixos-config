{ ... }:

{
  flake.nixosModules.immich =
    { config, pkgs-unstable, ... }:
    {
      # 26.05 ships Immich 2.7.5, which is EOL and marked insecure; 3.x is only
      # available from unstable.
      services.immich = {
        enable = true;
        package = pkgs-unstable.immich;
        host = "0.0.0.0";
      };

      systemd.services.immich-server.unitConfig.RequiresMountsFor = [
        config.services.immich.mediaLocation
      ];
    };
}
