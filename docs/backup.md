# Backup runbook (`srv`)

## What is backed up

`open-webui` state: `/var/lib/private/open-webui` is mirrored daily at 04:00
(`state-backup.timer`, persistent — missed runs happen on boot) to

```
/mnt/btrfs-pool/@backups/state/open-webui/
```

It is an exact 1:1 image of the source directory with the live SQLite files
(`*.db`, minus `-wal`/`-shm`, which make no sense copied live) replaced by
consistent single-file dumps from `sqlite3 .backup`, each verified with
`PRAGMA integrity_check` on every run. Retention is snapper's timeline on the
`backups` config (defaults: ~10 hourly + 7 daily snapshots); because the job
overwrites the same directory daily and btrfs is copy-on-write, each run only
consumes the changed blocks.

Not covered (decided, revisit if it matters):
- immich's photo metadata: PostgreSQL in `/var/lib/postgresql` — only the media
  on the pool is protected by snapshots.
- the sops identity: `/etc/ssh/ssh_host_ed25519_key`. Without it, the secrets in
  `secrets/` cannot be decrypted on a replacement machine — keep a copy
  somewhere safe.

## Checking it is intact

```sh
systemctl status state-backup.timer
systemctl list-timers state-backup
journalctl -u state-backup        # rsync output, integrity violations fail the unit
sudo ls -la /mnt/btrfs-pool/@backups/state/open-webui
```

## Restore on this host

```sh
sudo systemctl stop open-webui
sudo rsync -a --delete /mnt/btrfs-pool/@backups/state/open-webui/ /var/lib/private/open-webui/
sudo systemctl start open-webui
```

The stop/start window matters: open-webui holds the live database files open,
and starting restores ownership — the upstream unit runs as a `DynamicUser`
with `StateDirectory = "open-webui"`, and systemd re-applies ownership and
permissions of the state directory on every start, so no manual chown is
needed. `--delete` clears stale `*.db-wal`/`*.db-shm`, which would otherwise
be applied against the restored database and corrupt it.

## Restore an earlier point in time

```sh
sudo snapper -c backups list
```

Snapshot `n` is browsable at `/mnt/btrfs-pool/@backups/.snapshots/n/snapshot/`
(its `state/open-webui/` is the backup as it was then). Restore with the same
three commands, replacing the source directory accordingly.

## Host died

The array is independent of the host: mount it from any Linux (installer,
other machine) and copy `state/open-webui/` onto the replacement host's
`/var/lib/private/open-webui` before starting `open-webui`, then rebuild this
flake. Note that subject to the two "not covered" gaps above: secrets need the
SSH host key, immich's database is not in this backup.

## History

This replaced a borg job (repokey encryption, passphrase in sops, pruning,
snapshotting of the repo). The `borg-passphrase` key is still in
`secrets/srv.yaml` (inert; remove manually with `sops secrets/srv.yaml`) and
the old borg repo is at `/mnt/btrfs-pool/@backups/borg` (delete to reclaim
space; keep in mind retention snapshots hold the space until they age out)
— `sudo snapper -c backups list` / wait for snapshots to expire, then
`sudo rm -rf /mnt/btrfs-pool/@backups/borg`.
