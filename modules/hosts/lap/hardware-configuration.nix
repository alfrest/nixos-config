# Do not modify the generated settings below!  They come from ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes to the
# other modules in this directory instead.
{ ... }:

{
  flake.nixosModules.lap-hardware =
    { config, lib, pkgs, modulesPath, ... }:
    {
      imports =
        [ (modulesPath + "/installer/scan/not-detected.nix")
        ];

      boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" =
        { device = "/dev/disk/by-uuid/56428293-bfc7-4964-8bb5-2a1be9d128d9";
          fsType = "btrfs";
          options = [ "subvol=@" ];
        };

      fileSystems."/var" =
        { device = "/dev/disk/by-uuid/56428293-bfc7-4964-8bb5-2a1be9d128d9";
          fsType = "btrfs";
          options = [ "subvol=@var" ];
        };

      fileSystems."/home" =
        { device = "/dev/disk/by-uuid/56428293-bfc7-4964-8bb5-2a1be9d128d9";
          fsType = "btrfs";
          options = [ "subvol=@home" ];
        };

      fileSystems."/nix" =
        { device = "/dev/disk/by-uuid/56428293-bfc7-4964-8bb5-2a1be9d128d9";
          fsType = "btrfs";
          options = [ "subvol=@nix" ];
        };

      fileSystems."/.snapshots" =
        { device = "/dev/disk/by-uuid/56428293-bfc7-4964-8bb5-2a1be9d128d9";
          fsType = "btrfs";
          options = [ "subvol=@snapshots" ];
        };

      fileSystems."/boot" =
        { device = "/dev/disk/by-uuid/E7CE-608F";
          fsType = "vfat";
          options = [ "fmask=0077" "dmask=0077" ];
        };

      swapDevices = [ ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.npu.enable = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
