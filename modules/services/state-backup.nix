{ ... }:

{
  flake.nixosModules.state-backup =
    { config, pkgs, ... }:

    let
      src = "/var/lib/private/open-webui";
      dest = "/mnt/btrfs-pool/@backups/state/open-webui";
      readme = "/mnt/btrfs-pool/@backups/state/README.md";
    in

    {
      systemd.services.state-backup = {
        description = "Mirror open-webui state to the btrfs pool";
        path = [ pkgs.rsync pkgs.sqlite ];

        serviceConfig.Type = "oneshot";

        script = ''
          set -e
          mkdir -p "${dest}"

          # The live SQLite files cannot be copied as a set without tearing
          # (db, -wal and -shm are written independently), so they are
          # excluded and each database is rewritten onto its own name with
          # `sqlite3 .backup`, whose single-file output is guaranteed
          # consistent. The result is an exact 1:1 image of $src that can be
          # rsynced back in one command. `--delete` also purges stale
          # -wal/-shm files on restore.
          rsync -a --delete \
            --exclude='*.db' --exclude='*.db-wal' --exclude='*.db-shm' \
            "${src}/" "${dest}/"
          for db in ${src}/*.db; do
            [ -e "$db" ] || continue
            sqlite3 "$db" ".backup '${dest}/$(basename "$db")'"
            # A silently corrupt dump is worse than no backup.
            sqlite3 "${dest}/$(basename "$db")" 'PRAGMA integrity_check;' >/dev/null
          done

          cat > ${readme} <<'EOF'
Backup of /var/lib/private/open-webui, refreshed daily at 04:00 by
state-backup.service. The SQLite files in here are consistent dumps
(sqlite3 .backup), not live files. This file is rewritten on every run.

Restore on this host:
  sudo systemctl stop open-webui
  sudo rsync -a --delete /mnt/btrfs-pool/@backups/state/open-webui/ /var/lib/private/open-webui/
  sudo systemctl start open-webui

Restore an earlier state:
  sudo snapper -c backups list
  then the same rsync, pointing at
  /mnt/btrfs-pool/@backups/.snapshots/<n>/snapshot/state/open-webui/
  (keep --delete, it clears stale *.db-wal/*.db-shm files)

Host died:
  Mount the btrfs array from any Linux, copy state/open-webui/ onto the
  new machine's /var/lib/private/open-webui, then rebuild this flake
  before starting open-webui. Full runbook: docs/backup.md in the repo.
EOF
        '';
      };

      systemd.timers.state-backup = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "04:00";
          Persistent = true;
        };
      };
    };
}
