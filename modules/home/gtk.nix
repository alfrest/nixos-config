# GTK appearance. Home Manager writes both `~/.config/gtk-{3,4}.0/settings.ini`
# and the matching `org/gnome/desktop/interface` dconf keys.
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

          theme = {
            name = "adw-gtk3-dark";
            package = pkgs.adw-gtk3;
          };

          iconTheme = {
            name = "Adwaita";
            package = pkgs.adwaita-icon-theme;
          };

          colorScheme = "dark";
        };

        # Adwaita variants; `gtk.theme.package` already provides adw-gtk3.
        home.packages = [ pkgs.gnome-themes-extra ];
      };
    };
}
