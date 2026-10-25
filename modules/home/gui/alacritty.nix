# Alacritty. The theme comes from `pkgs.alacritty-theme` via Home Manager,
# which fails the build if the theme name is wrong.
#
# Font family `JetBrains Mono Nerd Font Mono` is literal: the extra `Mono`
# matches what `nerd-fonts.jetbrains-mono` provides.
#
# `Ctrl+Backspace` must be `"\\u0017"` (double backslash). Home Manager's TOML
# writer unescapes it to the `\u0017` alacritty expects; a single `\u0017`
# becomes a literal control character. `\x17` is not a valid TOML escape.
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
