# Meta module: the graphical stack (niri session, login, bar, audio) plus the
# per-user GUI modules. Headless hosts must not import this.
{ self, ... }:

{
  flake.nixosModules.desktop =
    { ... }:
    {
      imports = [
        self.nixosModules.desktop-graphics
        self.nixosModules.desktop-stylix
        self.nixosModules.desktop-niri
        self.nixosModules.desktop-noctalia
        self.nixosModules.desktop-greetd
        self.nixosModules.desktop-audio
        self.nixosModules.home-gui
      ];
    };
}
