{ config, pkgs, ... }:

{
  flake.nixosModules.webdav =
    { config, pkgs, ... }:
    {
      sops.secrets."webdav-pass" = {
        sopsFile = ../../secrets/srv.yaml;
        owner = "root";
        mode = "0400";
      };

      networking.firewall.allowedTCPPorts = [ 5001 ];

      systemd.services.rclone-webdav = {
        description = "WebDAV server for /srv/data";
        after = [ "network.target" "sops-nix.service" "srv-data.mount" ];
        wantedBy = [ "multi-user.target" ];
        unitConfig.ConditionPathIsMountPoint = "/srv/data";
        serviceConfig = {
          User = "alfrest";
          Group = "users";
          LoadCredential =
            "webdav-pass:${config.sops.secrets."webdav-pass".path}";
          ExecStart = pkgs.writeShellScript "rclone-webdav" ''
            exec ${pkgs.rclone}/bin/rclone serve webdav /srv/data \
              --config /dev/null \
              --addr :5001 \
              --user alfrest \
              --pass "$(cat "$CREDENTIALS_DIRECTORY/webdav-pass")"
          '';
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ReadWritePaths = "/srv/data";
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectHome = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
          SystemCallFilter = "@system-service";
        };
      };
    };
}
