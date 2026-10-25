# XDG base dirs. `xdg.enable` exports `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`,
# `XDG_DATA_HOME` and `XDG_STATE_HOME` for the whole session; niri, alacritty
# and Home Manager rely on them.
{ ... }:

{
  flake.nixosModules.home-xdg-user-dirs =
    { ... }:
    {
      home-manager.users.alfrest = {
        xdg.enable = true;

        xdg.userDirs = {
          enable = true;

          createDirectories = true;
        };

        # niri writes screenshots to `~/Pictures/Screenshots/`. Home Manager only
        # manages directories that contain something, so seed one with an empty
        # file.
        home.file."Pictures/Screenshots/.keep".text = "";
      };
    };
}
