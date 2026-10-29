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

      boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
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

      swapDevices = [ ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
