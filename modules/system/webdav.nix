# WebDAV file server for /srv/data (srv only).
#
# Plain rclone instead of SFTPGo: stateless, no provider database, one user and
# one folder. SFTP access already exists via OpenSSH. The password is a
# LoadCredential from sops, so it never lands in /proc cmdline of a store
# script — only in the running process' argv, readable by root and alfrest.
# Plain HTTP: fine on the LAN, but Windows Explorer refuses basic auth without
# TLS unless a registry tweak is applied; use SMB there.
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
        # The pool mounts with nofail; skip instead of failing when it is away,
        # like immich-server in hosts/srv/default.nix.
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
          # rclone is stateless: /srv/data is the only thing to write.
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
