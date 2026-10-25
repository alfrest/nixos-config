# Meta module: the graphical stack (niri session, login, bar) plus the
# per-user GUI modules. Headless hosts must not import this.
{ self, ... }:

{
  flake.nixosModules.desktop =
    { ... }:
    {
      imports = [
        self.nixosModules.desktop-graphics
        self.nixosModules.desktop-niri
        self.nixosModules.desktop-noctalia
        self.nixosModules.desktop-greetd
        self.nixosModules.home-gui
      ];
    };
}
