# Stylix supplies the GTK and Qt colour schemes from a single base16 palette.
#
# Only those two targets are on: `autoEnable = false` keeps Stylix away from
# fonts, icons, cursors, terminals, browsers, the boot splash and package
# overlays, so enabling it cannot silently theme anything else. A target needs
# to be enabled on the Home Manager side too, because `followSystem` copies
# `autoEnable` but not the target enable flags.
#
# Scheme: Horizon Dark from tinted-theming, shipped by nixpkgs as
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
      };

      # `stylix.homeManagerIntegration.autoImport` imports the Home Manager
      # module for every user; the targets themselves are enabled here.
      home-manager.users.alfrest.stylix.targets = {
        gtk.enable = true;
        qt.enable = true;
      };
    };
}
