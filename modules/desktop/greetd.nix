# greetd + tuigreet. `--cmd` is required: without it tuigreet falls back to the
# login shell and niri never starts.
#
# No autologin on purpose: the password typed at tuigreet is what unlocks
# gnome-keyring through PAM.
{ ... }:

{
  flake.nixosModules.desktop-greetd =
    { pkgs, ... }:
    {
      services.greetd = {
        enable = true;
        useTextGreeter = true;

        settings.default_session.command =
          "${pkgs.tuigreet}/bin/tuigreet --remember --remember-session --cmd ${pkgs.niri}/bin/niri-session";
      };
    };
}
