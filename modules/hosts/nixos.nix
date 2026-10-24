# The host aggregate: everything that is true for this machine lives here as
# a NixOS module under `flake.nixosModules`, and this file selects which of
# those modules make up the `nixos` configuration.
{ self, inputs, ... }:

{
  flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hardware
      self.nixosModules.boot
      self.nixosModules.networking
      self.nixosModules.openssh
      self.nixosModules.packages
      self.nixosModules.state-version
      self.nixosModules.user-alfrest
    ];
  };
}
