{ self, inputs, ... }:

let
  system = "x86_64-linux";

  # Unstable nixpkgs; modules see it as `pkgs-unstable`.
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};

  # `default` is the beta variant and installs `bin/zen-beta` (no `bin/zen`).
  zen-browser = inputs.zen-browser.packages.${system}.default;
in

{
  flake.nixosConfigurations.dsk = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit pkgs-unstable zen-browser; };

    modules = [
      # Physical display (`niri msg outputs` on the workstation).
      {
        networking.hostName = "dsk";
        desktop.niri.output = {
          name = "DP-2";
          mode = "2560x1440@239.958";
          scale = "1";
        };
        # Slower pointer than the shared default. libinput caps the adaptive
        # profile at `2.0 + 1.5 × accel-speed`: -0.6 → 1.1x, -0.9 → 0.65x,
        # so this is ~60% of the old speed.
        desktop.niri.mouse.accelSpeed = -0.9;
      }

      self.nixosModules.dsk-hardware
      self.nixosModules.boot

      self.nixosModules.base

      self.nixosModules.desktop

      self.nixosModules.desktop-nvidia

      self.nixosModules.desktop-openrgb
    ];
  };
}
