# Alacritty, ported from the Arch `alacritty` role.
#
# Source: `~/.config/alacritty/alacritty.toml` with a `git clone` of
# alacritty/alacritty-theme next to it, imported as
# `~/.config/alacritty/themes/themes/vscode.toml`.
#
# Here the theme comes from `pkgs.alacritty-theme` through Home Manager's
# `theme` option, which both interpolates the store path and fails the build if
# the theme name does not exist. No clone, no stale checkout.
#
# The font family string is `JetBrains Mono Nerd Font Mono` (the extra `Mono`
# matters — it is what the old machine used and what the installed
# nerd-fonts.jetbrains-mono provides).
#
# `Ctrl+Backspace` is bound to chars `\u0017` (ASCII ETX / Ctrl-W), so the shell
# deletes a word. In Nix the value must be written `"\\u0017"` (backslash-u),
# not `"\u0017"`: Home Manager's TOML writer then unescapes it to the single
# `\u0017` escape alacritty expects. The source TOML wrote `\x17`, which is not
# a valid TOML escape.
{ ... }:

{
  flake.nixosModules.home-alacritty =
    { ... }:
    {
      home-manager.users.alfrest.programs.alacritty = {
        enable = true;

        theme = "vscode";

        settings = {
          keyboard.bindings = [
            {
              key = "Backspace";
              mods = "Control";
              chars = "\\u0017";
            }
          ];

          font = {
            normal = {
              family = "JetBrains Mono Nerd Font Mono";
              style = "Regular";
            };
            bold = {
              family = "JetBrains Mono Nerd Font Mono";
              style = "Bold";
            };
            italic = {
              family = "JetBrains Mono Nerd Font Mono";
              style = "Italic";
            };
            size = 12;
          };
        };
      };
    };
}
