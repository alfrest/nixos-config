# greetd + tuigreet, the login path ported from the Arch `tuigreet` role.
#
# The role dropped a `config.toml` (tuigreet flags) into /etc/greetd and a
# hand-written /etc/pam.d/greetd. On NixOS neither file is written by hand: the
# greetd module generates both. What is left to say is which greeter runs and
# which command the session starts.
#
# Deliberate differences from the source role (plan §5 P13):
#   1. `--cmd ${pkgs.niri}/bin/niri-session` is **added**. The Arch config had
#      only `--remember --remember-session`, so tuigreet fell back to the login
#      shell and niri was never actually started by the greeter — the documented
#      parity target is "greetd → niri", so the command is spelled out here.
#   2. No /etc/pam.d/greetd template: the module declares
#      `security.pam.services.greetd` itself, including
#      `enableGnomeKeyring = config.services.gnome.gnome-keyring.enable`, which
#      P10 (modules/desktop/graphics.nix) turns on. That is what unlocks the
#      keyring with the login password instead of asking for it in-session.
#   3. `useTextGreeter = true`: tuigreet is a TUI, and the module uses the flag to
#      route systemd boot messages away from the greeter's tty.
#
# Not repeated because the greetd module already does it: `terminal.vt = 1`,
# `default_session.user = "greeter"`, `services.displayManager.enable = true`,
# the `/var/cache/tuigreet` state directory used by `--remember-session`, and
# disabling `autovt@tty1` (tty2–tty6 gettys stay reachable, which is the
# recovery path — see the plan).
#
# No `initial_session` (autologin) on purpose: the password typed at tuigreet is
# what unlocks gnome-keyring, and autologin would bypass PAM's keyring module.
#
# Lockout is the risk here, not configuration: OpenSSH stays enabled, the
# previous generation stays in the boot menu, and Ctrl+Alt+F2 gives a getty.
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
