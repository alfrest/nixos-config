{ ... }:

{
  flake.nixosModules.desktop-openrgb =
    { pkgs, ... }:
    {
      services.hardware.openrgb = {
        enable = true;
        startupProfile = "default"; # copy file from ~/.config/OpenRGB/default.orp to /var/lib/OpenRGB/
      };
    };
}
