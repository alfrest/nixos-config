{ ... }:

{
  flake.nixosModules.desktop-openrgb =
    { pkgs, ... }:
    {
      services.hardware.openrgb = {
        enable = true;
        startupProfile = "blue"; # copy file from ~/.config/OpenRGB/blue.orp to /var/lib/OpenRGB/
      };
    };
}
