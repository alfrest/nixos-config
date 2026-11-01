{ ... }:

{
  flake.nixosModules.borgbackup =
    { config, pkgs, ... }:
    {
      # Repokey encryption: the passphrase is the data key, so losing the value
      # in `secrets/srv.yaml` makes every archive unrecoverable.
      sops.secrets."borg-passphrase" = {
        sopsFile = ../../secrets/srv.yaml;
        key = "borg-passphrase";
      };

      services.borgbackup.jobs.open-webui = {
        paths = [
          "/run/open-webui-dump"
          "/var/lib/private/open-webui"
        ];

        # The live SQLite files are replaced by the consistent dump in
        # `/run/open-webui-dump`, which the unit creates before borg runs.
        exclude = [
          "/var/lib/private/open-webui/*.db"
          "/var/lib/private/open-webui/*.db-wal"
          "/var/lib/private/open-webui/*.db-shm"
        ];

        repo = "/mnt/btrfs-pool/@backups/borg/open-webui";

        encryption = {
          mode = "repokey-blake2";
          passCommand = "cat ${config.sops.secrets."borg-passphrase".path}";
        };

        compression = "auto,zstd";
        startAt = "04:00";
        persistentTimer = true;

        prune.keep = {
          daily = 7;
          weekly = 4;
          monthly = 6;
        };
      };

      # The module's own tmpfiles rule for the repo dir runs at boot, before
      # the (nofail-mounted) pool; it writes into the root fs and the mount
      # shadows it. Create the repo dir here instead, ordered after the mount.
      systemd.services."open-webui-borg-repo-dir" = {
        description = "Create the borg repo directory on the @backups subvolume";
        unitConfig.RequiresMountsFor = "/mnt/btrfs-pool";
        script = "mkdir -p /mnt/btrfs-pool/@backups/borg/open-webui";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      systemd.services."borgbackup-job-open-webui" = {
        after = [ "open-webui-borg-repo-dir.service" ];
        wants = [ "open-webui-borg-repo-dir.service" ];

        path = [ pkgs.sqlite ];

        serviceConfig.RuntimeDirectory = "open-webui-dump";

        # The pool is mounted with `nofail`; never write the repo to `/` when
        # the mount failed.
        unitConfig.ConditionPathIsMountPoint = "/mnt/btrfs-pool";

        # SQLite's online backup API yields a consistent copy while the
        # service keeps running.
        preStart = ''
          for db in /var/lib/private/open-webui/*.db; do
            [ -e "$db" ] || continue
            sqlite3 "$db" ".backup '/run/open-webui-dump/$(basename "$db")'"
          done
        '';
      };
    };
}
