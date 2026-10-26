# NVIDIA driver for a host with a dedicated GeForce card. Opt in per host; the
# VM keeps the virtio-gpu stack from `desktop-graphics`.
#
# Wayland-only: `services.xserver.videoDrivers` is just the selector the NVIDIA
# module keys off, it does not enable X11 (which would compete with niri for
# the TTY). `nvidia-drm.modeset=1` and `nvidia-drm.fbdev=1` come from
# `hardware.nvidia.moduleParams` on driver >= 545. nixpkgs only loads the
# modules eagerly when X11 is enabled, so do it here instead.
{ ... }:

{
  flake.nixosModules.desktop-nvidia =
    { config, lib, ... }:
    {
      # The driver is unfree; whitelist only its packages rather than turning
      # on `allowUnfree` for the whole host.
      nixpkgs.config.allowUnfreePredicate =
        pkg: builtins.elem (lib.getName pkg) [ "nvidia-x11" "nvidia-settings" ];

      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        # Turing and newer (Ampere here) are supported by the open modules,
        # which recent drivers require to be chosen explicitly.
        open = true;
        modesetting.enable = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      boot.kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_drm"
        "nvidia_uvm"
      ];
    };
}
