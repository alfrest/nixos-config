# Do not modify the generated settings below!  They come from ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes to the
# other modules in this directory instead.
{ ... }:

{
  flake.nixosModules.srv-hardware =
    { config, lib, pkgs, modulesPath, ... }:
    {
      imports =
        [ (modulesPath + "/installer/scan/not-detected.nix")
        ];

      boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "uas" "sd_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" =
        { device = "/dev/disk/by-uuid/15ced854-ec40-4c41-95aa-d371c79a8a2c";
          fsType = "ext4";
        };

      fileSystems."/boot" =
        { device = "/dev/disk/by-uuid/7A40-4CED";
          fsType = "vfat";
          options = [ "fmask=0077" "dmask=0077" ];
        };

      fileSystems."/mnt/btrfs-pool" =
        { device = "/dev/disk/by-uuid/5d3c3a5d-4a00-48ab-9530-08bcc1a7bfd7";
          fsType = "btrfs";
          options = [ "noatime" "compress=zstd:3" "nofail" ];
        };

      # Share mount for @data (top-level pool mount stays above for admin work
      # like snapshots). nofail on both: see srv/default.nix mount guards.
      fileSystems."/srv/data" =
        { device = "/dev/disk/by-uuid/5d3c3a5d-4a00-48ab-9530-08bcc1a7bfd7";
          fsType = "btrfs";
          options = [ "subvol=@data" "noatime" "compress=zstd:3" "nofail" ];
        };

      swapDevices = [ ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
