# Meta module: per-user pieces that only make sense in a graphical session.
{ self, ... }:

{
  flake.nixosModules.home-gui =
    { ... }:
    {
      imports = [
        self.nixosModules.home-alacritty
        self.nixosModules.home-media
        self.nixosModules.home-clipboard
      ];
    };
}
