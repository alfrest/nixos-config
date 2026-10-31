{ self, inputs, ... }:

let
  system = "x86_64-linux";

  # Unstable nixpkgs; modules see it as `pkgs-unstable`.
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};

  # `default` is the beta variant and installs `bin/zen-beta` (no `bin/zen`).
  zen-browser = inputs.zen-browser.packages.${system}.default;
in

{
  flake.nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit pkgs-unstable zen-browser; };

    modules = [
      # Virtual display (`niri msg outputs` on the VM); the preferred mode is
      # only 1280x800, so pin an advertised larger one.
      {
        networking.hostName = "vm";
        desktop.niri.output = {
          name = "Virtual-1";
          mode = "1920x1200@59.885";
        };
      }

      self.nixosModules.vm-hardware
      self.nixosModules.boot

      self.nixosModules.base

      self.nixosModules.desktop
    ];
  };
}
