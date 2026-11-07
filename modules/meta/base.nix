# Meta module: the baseline every host imports. Adding a feature here makes it
# part of every host, headless ones included.
{ self, ... }:

{
  flake.nixosModules.base =
    { ... }:
    {
      imports = [
        # System core, shared by every host.
        self.nixosModules.nix
        self.nixosModules.nix-ld
        self.nixosModules.networking
        self.nixosModules.locale
        self.nixosModules.openssh
        self.nixosModules.tailscale
        self.nixosModules.secrets
        self.nixosModules.packages
        self.nixosModules.state-version
        self.nixosModules.home-manager
        self.nixosModules.alfrest

        # Per-user defaults that work without a graphical session.
        self.nixosModules.xdg-user-dirs
        self.nixosModules.cli-tools
        self.nixosModules.git
        self.nixosModules.zsh
        self.nixosModules.herdr
        self.nixosModules.nvim
      ];
    };
}
