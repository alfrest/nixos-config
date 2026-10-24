# GTK appearance, ported from the Arch `gtk` role.
#
# The source role installed `gnome-themes-extra`, `adw-gtk-theme`,
# `python-psutil` and `python-gobject`, then used `community.general.dconf` to
# set `gtk-theme=adw-gtk3-dark` and `color-scheme=prefer-dark`.
#
# Home Manager's `gtk` module replaces both halves: it writes
# `~/.config/gtk-{3,4}.0/settings.ini` *and* the matching
# `org/gnome/desktop/interface` dconf keys. Note that `colorScheme = "dark"`
# is what produces `prefer-dark` in dconf; the option only accepts
# `"dark"` / `"light"`.
#
# `programs.dconf.enable` (system half) is required for that dconf write to
# succeed during activation — Home Manager's dconf module says so explicitly.
#
# The `python-*` packages were runtime dependencies of the Arch shell setup,
# not settings. They are not migrated: noctalia 5.0.1 starts and validates
# without them, so no Python packages are added for GTK.
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

          # dconf: color-scheme = prefer-dark
          colorScheme = "dark";
        };

        # `gtk.theme.package` already installs adw-gtk3 for the user; this is
        # the extra package the source role installed for the Adwaita variants.
        home.packages = [ pkgs.gnome-themes-extra ];
      };
    };
}
