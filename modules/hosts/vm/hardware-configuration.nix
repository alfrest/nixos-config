# Do not modify the generated settings below!  They come from ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes to the
# other modules in this directory instead.
#
# The file is wrapped in a flake-parts module so the generated description is
# exposed as `flake.nixosModules.vm-hardware` and selected through `self` like
# every other module of the `vm` host in this repository.
{ ... }:

{
  flake.nixosModules.vm-hardware =
    { config, lib, pkgs, modulesPath, ... }:
    {
      imports =
        [ (modulesPath + "/profiles/qemu-guest.nix")
        ];

      boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" =
        { device = "/dev/disk/by-uuid/583d66bb-104e-4821-9455-7a1b61d4080a";
          fsType = "btrfs";
          options = [ "subvol=@nixos-root" ];
        };

      fileSystems."/home" =
        { device = "/dev/disk/by-uuid/583d66bb-104e-4821-9455-7a1b61d4080a";
          fsType = "btrfs";
          options = [ "subvol=@nixos-home" ];
        };

      fileSystems."/boot" =
        { device = "/dev/disk/by-uuid/87E8-2A81";
          fsType = "vfat";
          options = [ "fmask=0077" "dmask=0077" ];
        };

      swapDevices = [ ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}
