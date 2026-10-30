{ ... }:

{
  flake.nixosModules.btrfs-scrub = {
    # The pool is also mounted through subvolumes; scrub the top-level mount
    # once so the same filesystem is not checked repeatedly.
    services.btrfs.autoScrub = {
      enable = true;
      fileSystems = [ "/mnt/btrfs-pool" ];
      interval = "*-*-01 03:00:00";
    };
  };
}
