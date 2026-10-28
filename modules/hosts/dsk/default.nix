# Host aggregate: selects the modules that make up `dsk`.
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
      }

      # Machine-specific description and boot loader.
      self.nixosModules.dsk-hardware
      self.nixosModules.boot

      # Defaults every host shares (system + non-GUI Home Manager modules).
      self.nixosModules.base

      # Graphical stack: niri, greetd, noctalia and the GUI Home Manager
      # modules. A headless host would stop here instead.
      self.nixosModules.desktop

      # RTX 3070: NVIDIA driver instead of the VM's virtio-gpu stack.
      self.nixosModules.desktop-nvidia

      # RGB lighting.
      self.nixosModules.desktop-openrgb
    ];
  };
}
