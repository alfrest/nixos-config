# niri config. `files/niri/config.kdl` is vendored with `@NAME@` placeholders
# for spawned programs; this module substitutes absolute store paths, so the
# file is written with `text =` rather than `mkOutOfStoreSymlink`.
#
# The display is per host via `desktop.niri.output` (below); `null` lets niri
# auto-configure it.
#
# Note: `Mod+B` uses `zen-beta` (the flake ships no `zen`), and the polkit agent
# lives at `libexec/polkit-kde-authentication-agent-1`, not `/usr/lib/...`.
# `xwayland-satellite` must be on PATH for X11 clients; niri spawns it itself.
{ ... }:

{
  flake.nixosModules.desktop-niri =
    { pkgs, zen-browser, config, lib, ... }:
    let
      cfg = config.desktop.niri;

      # KDL for one output, using `niri msg outputs` vocabulary. Nix indented
      # strings would strip the four-space indent, hence explicit strings.
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

      # libinput wants a float. `toString` renders six decimals ("-0.900000"),
      # `toJSON` gives the shortest form but drops the point for whole numbers
      # ("-1"), which niri's float parser would reject.
      accelSpeedStr =
        let
          s = builtins.toJSON cfg.mouse.accelSpeed;
        in
        if lib.hasInfix "." s then s else "${s}.0";

      configFile = builtins.replaceStrings
        [ "@NOCTALIA@" "@POLKIT@" "@TERMINAL@" "@BROWSER@" "@PLAYERCTL@" "@OUTPUT@" "@MOUSE_ACCEL@" ]
        [
          "${pkgs.noctalia}/bin/noctalia"
          "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
          "${pkgs.alacritty}/bin/alacritty"
          "${zen-browser}/bin/zen-beta"
          "${pkgs.playerctl}/bin/playerctl"
          outputBlock
          "accel-speed ${accelSpeedStr}"
        ]
        (builtins.readFile ./files/niri/config.kdl);
    in
    {
      options.desktop.niri.output = lib.mkOption {
        description = ''
          Display to pin in the niri config. `null` lets niri auto-configure
          the output.
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
                  Scale factor written verbatim into the KDL (`1`, `1.5`, …).
                  A string so `1` does not become `1.000000`.
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
                  Ask for variable refresh rate. Off by default: virtual outputs
                  usually report "not supported".
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

      options.desktop.niri.mouse.accelSpeed = lib.mkOption {
        type = lib.types.float;
        default = -0.6;
        example = -0.9;
        description = ''
          Pointer sensitivity for physical mice, written as `accel-speed` in the
          `mouse` section of the niri config. libinput's normalized range is
          -1.0 … 1.0 (0 = 1:1 movement).

          It is not a straight multiplier: with the default adaptive profile,
          libinput caps the pointer at `2.0 + 1.5 × accel-speed` times the
          nominal speed (`-0.6` → 1.1x, `-0.9` → 0.65x). To halve the current
          feel, lower the value rather than scaling it by 0.5.
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
