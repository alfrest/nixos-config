# Meta module: per-user defaults that work without a graphical session.
{ self, ... }:

{
  flake.nixosModules.home-common =
    { ... }:
    {
      imports = [
        self.nixosModules.home-xdg-user-dirs
        self.nixosModules.home-cli-tools
        self.nixosModules.home-git
        self.nixosModules.home-zsh
        self.nixosModules.home-herdr
        self.nixosModules.home-nvim
      ];
    };
}
