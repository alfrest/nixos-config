# noctalia config. `files/noctalia/config.toml` is vendored with `@WALLPAPER@`
# placeholders that this module points at store paths.
#
# `pkgs.noctalia` (5.x) is required, not `pkgs.noctalia-shell` (4.x): the config
# and binds use `noctalia msg`, which only 5.x provides.
#
# `polkit_agent = false` in the vendored file because niri already spawns the
# KDE polkit agent; two agents would race.
{ ... }:

{
  flake.nixosModules.desktop-noctalia =
    { pkgs, ... }:
    let
      wallpaper = pkgs.nixos-artwork.wallpapers.binary-black.gnomeFilePath;

      config = builtins.replaceStrings
        [ "@WALLPAPER_DIR@" "@WALLPAPER@" ]
        [ (builtins.dirOf wallpaper) wallpaper ]
        (builtins.readFile ./files/noctalia/config.toml);
    in
    {
      # Noctalia's Control Center hides its power-profile controls unless
      # power-profiles-daemon is on the bus. The battery widget reads
      # UPower over D-Bus; without it nothing shows in the bar.
      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;

      environment.systemPackages = [ pkgs.noctalia ];

      home-manager.users.alfrest.xdg.configFile."noctalia/config.toml".text = config;
    };
}
