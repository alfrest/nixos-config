# The host aggregate: everything that is true for this machine lives here as
# a NixOS module under `flake.nixosModules`, and this file selects which of
# those modules make up the `vm` configuration. The machine-generated
# hardware description sits next to this file and is selected the same way.
{ self, inputs, ... }:

let
  # The host is a plain x86_64 QEMU guest; the hardware module pins the same
  # default via `nixpkgs.hostPlatform`.
  system = "x86_64-linux";

  # A second, unstable nixpkgs instance. Only the few packages that are missing
  # from (or far behind in) stable are taken from it; everything else stays on
  # the stable `pkgs`. Modules see it as the `pkgs-unstable` argument.
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
in

{
  flake.nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit pkgs-unstable; };

    modules = [
      # Host identity: this machine is a QEMU VM.
      { networking.hostName = "vm"; }

      self.nixosModules.vm-hardware
      self.nixosModules.boot
      self.nixosModules.nix
      self.nixosModules.networking
      self.nixosModules.openssh
      self.nixosModules.packages
      self.nixosModules.state-version
      self.nixosModules.home-manager
      self.nixosModules.user-alfrest

      # Per-user feature modules (Home Manager).
      self.nixosModules.home-xdg-user-dirs
    ];
  };
}
