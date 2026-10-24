# Host aggregate: selects the modules that make up `vm`.
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
