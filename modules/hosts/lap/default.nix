{ self, inputs, ... }:

let
  system = "x86_64-linux";

  # Unstable nixpkgs; modules see it as `pkgs-unstable`.
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};

  # `default` is the beta variant and installs `bin/zen-beta` (no `bin/zen`).
  zen-browser = inputs.zen-browser.packages.${system}.default;
in

{
  flake.nixosConfigurations.lap = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit pkgs-unstable zen-browser; };

    modules = [
      {
        networking.hostName = "lap";
      }

      self.nixosModules.lap-hardware
      self.nixosModules.boot

      self.nixosModules.base

      self.nixosModules.desktop
    ];
  };
}
