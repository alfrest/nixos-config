# niri, the Wayland compositor, ported from the Arch `niri` role.
#
# The role shipped `~/.config/niri/config.kdl` (a Jinja template with the output
# block filled from `host_vars/dsk.yml`). Here the template is vendored under
# `files/niri/config.kdl` with every spawned program replaced by an `@NAME@`
# placeholder, and this module interpolates the absolute store paths. That is
# why the file is written with `text =` (a generated store file) instead of the
# `mkOutOfStoreSymlink` used for herdr/nvim: the content has to change.
#
# The output block is deliberately empty on this host. The workstation pinned
# `output "DP-2" { mode "2560x1440@239.958" scale 1 }`; a QEMU guest gets its
# output auto-configured, so copying that block would break the session.
#
# Differences from the source config (all deliberate, see the plan §5 P11):
#   - the `Mod+E` emacsclient bind is gone (emacs is out of scope),
#   - `Mod+B` starts the Zen browser from the P14 flake input, whose binary is
#     `zen-beta` (there is no `zen`),
#   - the polkit agent is spawned from its real NixOS location
#     (`libexec/polkit-kde-authentication-agent-1`, not `/usr/lib/...`),
#   - every other bind, the input/layout/gestures sections and the screenshot
#     path are verbatim.
#
# No login change yet: this phase only makes the session startable by hand
# (`niri-session` from a TTY). greetd follows in P13; `niri-session` comes from
# this package.
#
# Package placement: `alacritty` and `playerctl` are already in the per-user
# profile (P6/P14) and are spawned by absolute path, so they are not repeated
# here. `xwayland-satellite` must be on PATH because niri auto-spawns it for
# X11 clients (there is no NixOS module for it in 26.05). The polkit agent is a
# session-wide service, so it stays system-side.
{ ... }:

{
  flake.nixosModules.desktop-niri =
    { pkgs, zen-browser, ... }:
    let
      outputBlock = "";

      config = builtins.replaceStrings
        [ "@NOCTALIA@" "@POLKIT@" "@TERMINAL@" "@BROWSER@" "@PLAYERCTL@" "@OUTPUT@" ]
        [
          "${pkgs.noctalia}/bin/noctalia"
          "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
          "${pkgs.alacritty}/bin/alacritty"
          "${zen-browser}/bin/zen-beta"
          "${pkgs.playerctl}/bin/playerctl"
          outputBlock
        ]
        (builtins.readFile ./files/niri/config.kdl);
    in
    {
      environment.systemPackages = with pkgs; [
        niri
        xwayland-satellite
        kdePackages.polkit-kde-agent-1
      ];

      home-manager.users.alfrest.xdg.configFile."niri/config.kdl".text = config;
    };
}
