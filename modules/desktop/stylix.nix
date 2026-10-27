# Stylix owns the colour scheme, fonts, icons and cursor.
#
# `autoEnable = false` keeps Stylix away from terminals, browsers, editors, the
# boot splash and package overlays, so only the targets listed below are
# themed. Targets need enabling on the Home Manager side too, because
# `followSystem` copies `autoEnable` but not the target enable flags.
#
# Scheme: Kanagawa Dragon from tinted-theming, shipped by nixpkgs as
# `pkgs.base16-schemes` (the file there is identical to the spec-0.11 branch).
{ inputs, ... }:

{
  flake.nixosModules.desktop-stylix =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      stylix = {
        enable = true;
        autoEnable = false;

        # The scheme is dark; this only tells targets which variant to pick.
        polarity = "dark";
        base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa-dragon.yaml";

        # `JetBrainsMono Nerd Font Mono` is the family name the Nerd Font
        # package actually ships; alacritty keeps its own font settings.
        fonts = {
          sansSerif = {
            package = pkgs.inter;
            name = "Inter";
          };
          serif = {
            package = pkgs.source-serif;
            name = "Source Serif 4";
          };
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font Mono";
          };
        };

        cursor = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
          size = 16;
        };

        icons = {
          enable = true;
          package = pkgs.adwaita-icon-theme;
          light = "Adwaita";
          dark = "Adwaita";
        };

        # The NixOS half of the GTK target only enables dconf, which Home
        # Manager's GTK settings need; the theming itself is below.
        targets.gtk.enable = true;
      };

      home-manager.users.alfrest = {
        stylix.targets = {
          gtk.enable = true;
          qt.enable = true;
          fontconfig.enable = true;
          font-packages.enable = true;
        };

        # Stylix does not write `org.gnome.desktop.interface color-scheme`, so
        # without this libadwaita apps pick the light variant of adw-gtk3.
        gtk.colorScheme = "dark";
      };
    };
}
