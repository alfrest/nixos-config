# Client side of the WebDAV share served by srv: an rclone FUSE mount at
# `~/Shared` with the full VFS cache. Connects through srv's Caddy
# (`webdav.alfrest.net`, TLS there) rather than the raw rclone port. Opt-in
# (never on srv itself, which is the server); imported by the hosts that need it.
{ ... }:

{
  flake.nixosModules.webdav-mount =
    { config, pkgs, ... }:
    {
      sops.secrets."webdav-pass" = {
        sopsFile = ../../secrets/common.yaml;
        owner = "root";
        mode = "0400";
      };

      systemd.services.rclone-webdav-mount = {
        description = "rclone mount of srv's WebDAV share at ~alfrest/Shared";
        after = [ "network-online.target" "tailscaled.service" "sops-nix.service" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          # `--log-systemd` is what makes rclone send the systemd READY notification.
          Type = "notify";
          User = "alfrest";
          Group = "users";
          LoadCredential =
            "webdav-pass:${config.sops.secrets."webdav-pass".path}";
          # Restart while srv or the tailnet is unreachable, then keep retrying:
          # 15 s is longer than the default start-limit window, so no burst cap.
          Restart = "on-failure";
          RestartSec = 15;
          TimeoutStopSec = 30;
          ExecStart = pkgs.writeShellScript "rclone-webdav-mount" ''
            set -euo pipefail
            # fusermount only works unprivileged through the setuid wrapper.
            export PATH="${config.security.wrapperDir}:${pkgs.rclone}/bin:$PATH"

            # rclone only accepts an obscured password. `obscure` reads it from
            # stdin, so the plaintext never reaches argv or rclone's environment.
            pass=$(cat "$CREDENTIALS_DIRECTORY/webdav-pass")
            obscured=$(printf %s "$pass" | rclone obscure -)
            unset pass

            export RCLONE_CONFIG_SRVWEBDAV_TYPE=webdav
            export RCLONE_CONFIG_SRVWEBDAV_URL=https://webdav.alfrest.net
            export RCLONE_CONFIG_SRVWEBDAV_VENDOR=rclone
            export RCLONE_CONFIG_SRVWEBDAV_USER=alfrest
            export RCLONE_CONFIG_SRVWEBDAV_PASS="$obscured"
            unset obscured

            mkdir -p /home/alfrest/Shared
            exec rclone mount srvwebdav: /home/alfrest/Shared \
              --config /dev/null \
              --log-systemd \
              --vfs-cache-mode full \
              --vfs-cache-max-size 20G \
              --vfs-cache-max-age 720h
          '';
          # Belt and braces: drop the mount if rclone died without unmounting.
          ExecStop = "${config.security.wrapperDir}/fusermount3 -uz /home/alfrest/Shared";
        };
        # The mount needs the setuid fusermount wrapper, so the usual
        # NoNewPrivileges/RestrictSUIDSGID/ProtectHome hardening cannot apply.
      };
    };
}
