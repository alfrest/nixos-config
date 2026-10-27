# Meta module: system-level defaults shared by every host, GUI or headless.
#
# Boot loader settings stay out: they describe the machine (`boot.nix` is
# imported by each host) rather than the common baseline.
{ self, ... }:

{
  flake.nixosModules.system-common =
    { ... }:
    {
      imports = [
        self.nixosModules.nix
        self.nixosModules.networking
        self.nixosModules.locale
        self.nixosModules.openssh
        self.nixosModules.secrets
        self.nixosModules.packages
        self.nixosModules.state-version
        self.nixosModules.home-manager
        self.nixosModules.user-alfrest
      ];
    };
}
