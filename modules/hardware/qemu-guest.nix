# Wraps the machine-generated hardware description as a NixOS module so that
# it can be referenced through `flake.nixosModules` like every other module.
{ ... }:

{
  flake.nixosModules.hardware = {
    imports = [ ../../hardware-configuration.nix ];
  };
}
