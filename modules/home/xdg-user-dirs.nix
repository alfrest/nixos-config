# XDG base directories and the standard user dirs.
#
# Ported from the Arch `xdg_user_dirs` role, which installed the
# `xdg-user-dirs` package and ran `xdg-user-dirs-update` once. Home Manager
# does both declaratively: enabling `xdg.userDirs` pulls in the package and
# writes `~/.config/user-dirs.dirs`, so no imperative one-shot task remains.
#
# `xdg.enable` is set explicitly because it also exports the base variables
# (`XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`) for
# the whole session; niri, alacritty and Home Manager itself all rely on them.
{ ... }:

{
  flake.nixosModules.home-xdg-user-dirs =
    { ... }:
    {
      home-manager.users.alfrest = {
        xdg.enable = true;

        xdg.userDirs = {
          enable = true;

          # Create missing directories on activation. The defaults are the same
          # set the Arch machine had (Desktop, Documents, Downloads, Music,
          # Pictures, Public, Templates, Videos), so they are not overridden.
          createDirectories = true;
        };

        # niri writes screenshots to `~/Pictures/Screenshots/...` (see the
        # `screenshot-path` of the niri config in the desktop suite migration).
        # The directory has to exist before the first screenshot, so seed it
        # with an empty file: Home Manager only manages directories that
        # contain something.
        home.file."Pictures/Screenshots/.keep".text = "";
      };
    };
}
