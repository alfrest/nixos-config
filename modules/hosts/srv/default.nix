{ self, inputs, ... }:

let
  system = "x86_64-linux";

  # Unstable nixpkgs; modules see it as `pkgs-unstable`.
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
in

{
  flake.nixosConfigurations.srv = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit pkgs-unstable; };

    modules = [
      # Headless: `base` only, never the `desktop` meta module.
      { networking.hostName = "srv"; }

      self.nixosModules.srv-hardware
      self.nixosModules.boot

      self.nixosModules.base
    ];
  };
}
