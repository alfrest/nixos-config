{ lib, ... }:

{
  flake.nixosModules.snapper = {
    services.snapper.configs = lib.genAttrs [ "appdata" "backups" "data" ] (name: {
      SUBVOLUME = "/mnt/btrfs-pool/@${name}";
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
    });
  };
}
