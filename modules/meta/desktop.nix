# Meta module: the graphical stack (niri session, login, bar, audio) plus the
# per-user GUI modules. Headless hosts must not import this.
{ self, ... }:

{
  flake.nixosModules.desktop =
    { ... }:
    {
      imports = [
        self.nixosModules.graphics
        self.nixosModules.stylix
        self.nixosModules.niri
        self.nixosModules.noctalia
        self.nixosModules.greetd
        self.nixosModules.audio
        self.nixosModules.nix-ld-gui

        self.nixosModules.alacritty
        self.nixosModules.apps
        self.nixosModules.clipboard
      ];
    };
}
