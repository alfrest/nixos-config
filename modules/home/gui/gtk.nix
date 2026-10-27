# GTK appearance. Stylix owns the theme name/palette and the generated
# `gtk-{3,4}.0/gtk.css` (`modules/desktop/stylix.nix`); do not set
# `gtk.theme` here or the two modules conflict.
#
# `colorScheme = "dark"` is what produces `prefer-dark` in dconf; the option only
# accepts `"dark"` / `"light"`. `programs.dconf.enable` (system half) is
# required for the dconf write to succeed at activation.
{ ... }:

{
  flake.nixosModules.home-gtk =
    { pkgs, ... }:
    {
      programs.dconf.enable = true;

      home-manager.users.alfrest = {
        gtk = {
          enable = true;

          iconTheme = {
            name = "Adwaita";
            package = pkgs.adwaita-icon-theme;
          };

          colorScheme = "dark";
        };
      };
    };
}
