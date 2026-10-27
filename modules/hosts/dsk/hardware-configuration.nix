# Do not modify the generated settings below!  They come from ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes to the
# other modules in this directory instead.
{ ... }:

{
  flake.nixosModules.dsk-hardware =
    { config, lib, pkgs, modulesPath, ... }:
    {
      imports =
        [ (modulesPath + "/installer/scan/not-detected.nix")
        ];

      boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" =
        { device = "/dev/disk/by-uuid/d00afbc1-f391-4cbf-94fd-9ba05a7e3678";
          fsType = "btrfs";
          options = [ "subvol=@" "noatime" "compress=zstd:3" ];
        };

      fileSystems."/var" =
        { device = "/dev/disk/by-uuid/d00afbc1-f391-4cbf-94fd-9ba05a7e3678";
          fsType = "btrfs";
          options = [ "subvol=@var" "noatime" "compress=zstd:3" ];
        };

      fileSystems."/home" =
        { device = "/dev/disk/by-uuid/d00afbc1-f391-4cbf-94fd-9ba05a7e3678";
          fsType = "btrfs";
          options = [ "subvol=@home" "noatime" "compress=zstd:3" ];
        };

      fileSystems."/nix" =
        { device = "/dev/disk/by-uuid/d00afbc1-f391-4cbf-94fd-9ba05a7e3678";
          fsType = "btrfs";
          options = [ "subvol=@nix" "noatime" "compress=zstd:3" ];
        };

      fileSystems."/.snapshots" =
        { device = "/dev/disk/by-uuid/d00afbc1-f391-4cbf-94fd-9ba05a7e3678";
          fsType = "btrfs";
          options = [ "subvol=@snapshots" "noatime" "compress=zstd:3" ];
        };

      fileSystems."/boot" =
        { device = "/dev/disk/by-uuid/98C3-70B0";
          fsType = "vfat";
          options = [ "fmask=0077" "dmask=0077" ];
        };

      swapDevices = [ ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
