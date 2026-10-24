# Wayland prerequisites. This starts nothing; greetd launches the session.
#
# `hardware.graphics.enable` is the 26.05 name (`hardware.opengl` is gone).
# Do not add `services.xserver`: niri is not an X11, and a second display stack
# can steal the TTY. X11 apps go through xwayland-satellite (installed by the
# niri module).
{ ... }:

{
  flake.nixosModules.desktop-graphics =
    { pkgs, ... }:
    {
      hardware.graphics.enable = true;

      # greetd's PAM stack unlocks the keyring at login.
      services.gnome.gnome-keyring.enable = true;

      security.polkit.enable = true;

      # `niri` is the portal config name xdg-desktop-portal uses for this session.
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
        ];
        config.niri.default = [
          "gnome"
          "gtk"
        ];
      };

      environment.sessionVariables = {
        # Wayland-native rendering for Chromium/Electron apps (zen browser).
        NIXOS_OZONE_WL = "1";

        # Only if niri cannot create a GL context (no working virgl):
        # LIBGL_ALWAYS_SOFTWARE = "1";
      };
    };
}
