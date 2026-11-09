{ ... }:

{
  flake.nixosModules.nextcloud =
    { config, ... }:
    {
      sops.secrets."nextcloud-admin-password" = {
        sopsFile = ../../secrets/srv.yaml;
      };

      services.nextcloud = {
        enable = true;
        hostName = "cloud.alfrest.net";

        # Data and config live on the btrfs pool, so snapper's `appdata`
        # snapshots cover the files.
        datadir = "/mnt/btrfs-pool/@appdata/nextcloud";

        database.createLocally = true;
        config = {
          dbtype = "pgsql";
          adminpassFile = config.sops.secrets."nextcloud-admin-password".path;
        };

        settings = {
          # TLS terminates at Caddy; without these Nextcloud generates http://
          # links and logs the proxy IP instead of clients'.
          overwriteprotocol = "https";
          overwrite.cli.url = "https://cloud.alfrest.net";
          trusted_proxies = [ "127.0.0.1" ];
          default_phone_region = "SE";
        };
      };

      # The module's nginx vhost would take :80, which belongs to Caddy;
      # serve it on localhost for Caddy to proxy to.
      services.nginx.virtualHosts."cloud.alfrest.net".listen = [
        {
          addr = "127.0.0.1";
          port = 8081;
        }
      ];

      # The pool is mounted with `nofail`; do not start against the root
      # filesystem if it failed to mount (same guard as immich).
      systemd.services.nextcloud-setup.unitConfig = {
        RequiresMountsFor = [ "/mnt/btrfs-pool/@appdata/nextcloud" ];
        ConditionPathIsMountPoint = "/mnt/btrfs-pool";
      };
      systemd.services.phpfpm-nextcloud.unitConfig.ConditionPathIsMountPoint = "/mnt/btrfs-pool";
      systemd.services.nextcloud-cron.unitConfig.ConditionPathIsMountPoint = "/mnt/btrfs-pool";
    };
}
