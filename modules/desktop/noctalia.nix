# noctalia, the shell that draws the bar, launcher, control center, lock screen
# and handles volume/brightness on this desktop. Ported from the Arch `noctalia`
# role.
#
# The role shipped one `~/.config/noctalia/config.toml` with bar geometry, the
# launcher keybinds, the Inter font, the ADW community palette and a wallpaper
# under `/usr/share/backgrounds/archlinux` (an Arch package that nixpkgs does
# not carry). The file is vendored under `files/noctalia/config.toml` with the
# wallpaper directory and path left as placeholders, so this module can point
# them at a store path.
#
# Wallpaper decision (D6): `pkgs.nixos-artwork.wallpapers.moonscape`. The VM has
# no Arch backgrounds; moonscape is the closest match in darkness to the old
# `gritty.png`. Changing it is a one-line edit here — `gnomeFilePath` is the PNG
# path, `dirOf` its directory, and both end up in the config as store paths.
#
# Config file location must stay `~/.config/noctalia/config.toml`: that is where
# noctalia looks, and where the Arch setup put it.
#
# polkit: the niri config (P11) spawns the KDE agent, so this config sets
# `polkit_agent = false` to avoid running two authentication agents. The
# distinction is made in the vendored file itself; see its header.
#
# The package is `pkgs.noctalia` (5.x, Quickshell/Qt), not `pkgs.noctalia-shell`
# (4.7.6): the config and the old binds use `noctalia msg …`, which only the
# 5.x package provides.
{ ... }:

{
  flake.nixosModules.desktop-noctalia =
    { pkgs, ... }:
    let
      wallpaper = pkgs.nixos-artwork.wallpapers.moonscape.gnomeFilePath;

      config = builtins.replaceStrings
        [ "@WALLPAPER_DIR@" "@WALLPAPER@" ]
        [ (builtins.dirOf wallpaper) wallpaper ]
        (builtins.readFile ./files/noctalia/config.toml);
    in
    {
      environment.systemPackages = [ pkgs.noctalia ];

      home-manager.users.alfrest.xdg.configFile."noctalia/config.toml".text = config;
    };
}
