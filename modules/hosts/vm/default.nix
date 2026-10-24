# The host aggregate: everything that is true for this machine lives here as
# a NixOS module under `flake.nixosModules`, and this file selects which of
# those modules make up the `vm` configuration. The machine-generated
# hardware description sits next to this file and is selected the same way.
{ self, inputs, ... }:

{
  flake.nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      # Host identity: this machine is a QEMU VM.
      { networking.hostName = "vm"; }

      self.nixosModules.vm-hardware
      self.nixosModules.boot
      self.nixosModules.networking
      self.nixosModules.openssh
      self.nixosModules.packages
      self.nixosModules.state-version
      self.nixosModules.user-alfrest
    ];
  };
}
