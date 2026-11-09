{ ... }:

{
  flake.nixosModules.ulx3s =
    { pkgs, ... }:
    {
      services.udev.extraRules = ''
        # ULX3S (FTDI FT231X): world-readable so browser-based tooling
        # (WebUSB/Web Serial) can claim it, and ftdi_sio unloaded on hotplug
        # since NixOS has no /sbin/rmmod — use the store path.
        ACTION=="add", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6015", MODE="0666", RUN+="${pkgs.kmod}/bin/rmmod ftdi_sio"
      '';
    };
}
