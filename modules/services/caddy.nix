{ ... }:

{
  flake.nixosModules.caddy =
    { config, pkgs, ... }:
    let
      domain = "alfrest.net";

      # Stock Caddy has no third-party modules; the Cloudflare DNS provider is
      # required for the DNS-01 challenge that issues public certificates of
      # every virtual host below.
      caddy-cloudflare = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
        hash = "sha256-tubXIDCJnO2mvdnPlZclwDhNGaeeYLSt7lnni3+pXDo=";
      };
    in
    {
      sops.secrets."cloudflare-api-token" = {
        sopsFile = ../../secrets/srv.yaml;
      };

      # acme_dns reads the token from the process environment, so it only
      # ever lives in this rendered file, never in the store.
      sops.templates."caddy-env" = {
        content = "CF_API_TOKEN=${config.sops.placeholder."cloudflare-api-token"}\n";
        restartUnits = [ "caddy.service" ];
      };

      services.caddy = {
        enable = true;
        package = caddy-cloudflare;
        openFirewall = true;
        environmentFile = config.sops.templates."caddy-env".path;

        # DNS-01 for all automatically managed certificates: the server is
        # only reachable via Tailscale/LAN, so the HTTP-01 challenge could
        # never be solved by anything from outside.
        globalConfig = ''
          acme_dns cloudflare {$CF_API_TOKEN}
        '';

        virtualHosts = {
          "immich.${domain}".extraConfig = ''
            reverse_proxy 127.0.0.1:2283
          '';

          "chat.${domain}".extraConfig = ''
            reverse_proxy 127.0.0.1:8787
          '';

          "webdav.${domain}".extraConfig = ''
            reverse_proxy 127.0.0.1:5001
          '';

          "torrent.${domain}".extraConfig = ''
            reverse_proxy 127.0.0.1:8080
          '';
        };
      };

      # Wait until the token has been rendered so the first start succeeds.
      systemd.services.caddy.after = [ "sops-nix.service" ];
    };
}
