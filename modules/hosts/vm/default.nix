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

  # Zen browser from the community flake (see flake.nix). It is not in nixpkgs,
  # so it is passed down as its own argument; modules see it as `zen-browser`.
  # The flake's `default` package is its `beta` variant and installs
  # `bin/zen-beta` (there is no `bin/zen`); niri interpolates that path for
  # `Mod+B`.
  zen-browser = inputs.zen-browser.packages.${system}.default;
in

{
  flake.nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit pkgs-unstable zen-browser; };

    modules = [
      # Host identity: this machine is a QEMU VM, and its virtual display has a
      # fixed modes list. The values come from `niri msg outputs` on the running
      # VM: the output is `Virtual-1`, and 1920x1200@59.885 is one of the
      # advertised modes (the preferred one is only 1280x800, so it has to be
      # pinned). Scale/transform/position keep their option defaults.
      {
        networking.hostName = "vm";
        desktop.niri.output = {
          name = "Virtual-1";
          mode = "1920x1200@59.885";
        };
      }

      self.nixosModules.vm-hardware
      self.nixosModules.boot
      self.nixosModules.nix
      self.nixosModules.networking
      self.nixosModules.openssh
      self.nixosModules.packages
      self.nixosModules.state-version
      self.nixosModules.home-manager
      self.nixosModules.user-alfrest

      # System-level desktop pieces (Wayland session, login).
      self.nixosModules.desktop-graphics
      self.nixosModules.desktop-niri
      self.nixosModules.desktop-noctalia
      self.nixosModules.desktop-greetd

      # Per-user feature modules (Home Manager).
      self.nixosModules.home-xdg-user-dirs
      self.nixosModules.home-fonts
      self.nixosModules.home-cli-tools
      self.nixosModules.home-git
      self.nixosModules.home-zsh
      self.nixosModules.home-gtk
      self.nixosModules.home-alacritty
      self.nixosModules.home-herdr
      self.nixosModules.home-media
      self.nixosModules.home-nvim
    ];
  };
}
