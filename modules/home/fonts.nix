# Fonts. Family names are load-bearing: alacritty asks for
# `JetBrains Mono Nerd Font Mono` (extra `Mono`), noctalia for `Inter`.
{ ... }:

{
  flake.nixosModules.home-fonts =
    { pkgs, ... }:
    {
      home-manager.users.alfrest = {
        # Per-user fontconfig cache and `~/.config/fontconfig`.
        fonts.fontconfig.enable = true;

        home.packages = with pkgs; [
          inter
          source-serif
          nerd-fonts.jetbrains-mono
          nerd-fonts.fira-code
        ];
      };
    };
}
