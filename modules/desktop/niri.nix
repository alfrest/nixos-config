# niri, the Wayland compositor, ported from the Arch `niri` role.
#
# The role shipped `~/.config/niri/config.kdl` (a Jinja template with the output
# block filled from `host_vars/dsk.yml`). Here the template is vendored under
# `files/niri/config.kdl` with every spawned program replaced by an `@NAME@`
# placeholder, and this module interpolates the absolute store paths. That is
# why the file is written with `text =` (a generated store file) instead of the
# `mkOutOfStoreSymlink` used for herdr/nvim: the content has to change.
#
# The display is per host, so it is an option rather than a literal:
# `desktop.niri.output` (below) renders the KDL `output` block. `null` leaves
# the output auto-configured; the VM sets its own name and mode in
# `modules/hosts/vm/default.nix`. The old workstation's
# `output "DP-2" { mode "2560x1440@239.958" scale 1 }` is what used to be
# hard-coded in the template — it is not copied anywhere, the VM value comes
# from `niri msg outputs` on the VM itself.
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
    { pkgs, zen-browser, config, lib, ... }:
    let
      cfg = config.desktop.niri;

      # KDL for one output, straight from `niri msg outputs` vocabulary: the
      # name is the parenthesised identifier (`Virtual-1`), the mode string is
      # one of the "Available modes" (`1920x1200@59.885`). Quoted strings
      # everywhere: Nix indented strings would strip the four-space indent.
      renderOutput =
        output:
        lib.concatStringsSep "\n" (
          [ "output \"${output.name}\" {" ]
          ++ lib.optional (output.mode != null) "    mode \"${output.mode}\""
          ++ [ "    scale ${output.scale}" ]
          ++ [ "    transform \"${output.transform}\"" ]
          ++ lib.optional (output.position != null) "    position ${output.position}"
          ++ lib.optional output.variableRefreshRate "    variable-refresh-rate"
          ++ [ "}" ]
        );

      outputBlock = if cfg.output == null then "" else "\n" + renderOutput cfg.output;

      configFile = builtins.replaceStrings
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
      options.desktop.niri.output = lib.mkOption {
        description = ''
          Display to pin in the niri config. Leave `null` to let niri
          auto-configure the output, which is what a guest with an
          uncooperative virtual display wants. Each host chooses its own values
          from `niri msg outputs`; they are not shared.
        '';
        type = lib.types.nullOr (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                example = "Virtual-1";
                description = "Output name: the parenthesised identifier in `niri msg outputs`.";
              };

              mode = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                example = "1920x1200@59.885";
                description = ''
                  Mode string from the "Available modes" list, including the
                  refresh rate. `null` keeps the output's preferred mode.
                '';
              };

              scale = lib.mkOption {
                type = lib.types.str;
                default = "1";
                example = "1.5";
                description = ''
                  Scale factor, written verbatim into the KDL (`1`, `1.5`, …).
                  A string, not a float: the config is a text file and this way
                  `1` does not become `1.000000`.
                '';
              };

              transform = lib.mkOption {
                type = lib.types.str;
                default = "normal";
                description = "Rotation: `normal`, `90`, `180`, `270`, `flipped`, …";
              };

              position = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = "x=0 y=0";
                example = "x=1920 y=0";
                description = "Placement in the global coordinate space, as KDL (`x=0 y=0`). `null` omits the line.";
              };

              variableRefreshRate = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = ''
                  Ask for variable refresh rate. Defaults to off: virtual
                  outputs usually report "not supported", and the old
                  workstation's `variable-refresh-rate` line was about real
                  hardware.
                '';
              };
            };
          }
        );
        default = null;
        example = lib.literalExpression ''
          {
            name = "Virtual-1";
            mode = "1920x1200@59.885";
          }
        '';
      };

      config = {
        environment.systemPackages = with pkgs; [
          niri
          xwayland-satellite
          kdePackages.polkit-kde-agent-1
        ];

        home-manager.users.alfrest.xdg.configFile."niri/config.kdl".text = configFile;
      };
    };
}
