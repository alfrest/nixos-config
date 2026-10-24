# Graphics prerequisites for a Wayland session on this VM.
#
# This module only makes a Wayland session *possible*: it starts nothing at
# boot. greetd (modules/desktop/greetd.nix) is what launches the session.
#
# Verified before writing this module: /dev/dri exposes `card1` (Virtual-1) and
# `renderD128`, so Mesa/EGL can work with the VM's virtio-gpu (decision D1).
#
# `hardware.graphics.enable` is the 26.05 name (`hardware.opengl` is gone).
# Do not add `services.xserver`: niri is not an X11 session, and a second
# display stack can steal the TTY. X11 apps go through xwayland-satellite,
# which the niri module installs.
{ ... }:

{
  flake.nixosModules.desktop-graphics =
    { pkgs, ... }:
    {
      hardware.graphics.enable = true;

      # greetd's PAM stack unlocks this at login (see modules/desktop/greetd.nix).
      services.gnome.gnome-keyring.enable = true;

      # Default is true; stated explicitly because the niri session relies on it.
      security.polkit.enable = true;

      # Portals: file chooser, screenshot, screencast. `niri` is the portal
      # config name used by xdg-desktop-portal for the niri session.
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

        # Only if the VM has no working virgl and niri cannot create a GL
        # context — do not enable pre-emptively:
        # LIBGL_ALWAYS_SOFTWARE = "1";
      };
    };
}
