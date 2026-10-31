# BlueZ bluetooth. Only the daemon; pairing can be done with `bluetoothctl`
# (or noctalia's widget). Audio over bluetooth relies on PipeWire, so this
# module is meant to sit next to `audio` for headphones to work.
{ ... }:

{
  flake.nixosModules.bluetooth = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
