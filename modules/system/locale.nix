# Locale, time zone and keyboard layout.
#
# `time.timeZone` has no default: unset means UTC, which is an hour behind
# Stockholm in winter (CET) and two in summer (CEST). Hardware clock is kept in
# UTC, so only this setting decides what `date` shows.
#
# `console.keyMap` is the TTY/console layout — it applies to the login prompt,
# the recovery shell and anything before greetd starts. It does **not** affect
# niri, which sets its own `xkb { layout "se" }` in `files/niri/config.kdl`.
# `services.xserver.xkb.layout` is not needed here: there is no X server, and
# XWayland inherits the layout from niri.
{ ... }:

{
  flake.nixosModules.locale = {
    time.timeZone = "Europe/Stockholm";

    # Swedish keyboard on the console, with the layout niri uses as well.
    console.keyMap = "sv-latin1";
  };
}
