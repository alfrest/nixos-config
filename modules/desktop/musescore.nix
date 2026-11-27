# MuseScore 4 opens and plays `.mscz` scores. Opt-in per host (currently
# only `lap`): unlike the rest of the desktop stack it is not pulled in by
# the `desktop` meta module.
{ ... }:

{
  flake.nixosModules.musescore =
    { pkgs, ... }:
    {
      home-manager.users.alfrest = {
        home.packages = with pkgs; [
          musescore
        ];

        # The package registers `application/x-musescore` for `*.mscz`, so
        # the association makes double-clicking a score in Nautilus open it.
        xdg.mimeApps = {
          enable = true;
          defaultApplications."application/x-musescore" = "org.musescore.MuseScore.desktop";
        };
      };
    };
}
