# Fonts used by the desktop: Inter (shell/UI), Source Serif (serif fallback),
# and the two Nerd Font families the old machine installed.
#
# Ported from the Arch `fonts` role. That role split by distro: pacman got
# `inter-font`, `adobe-source-serif-fonts` and `ttf-jetbrains-mono-nerd`, while
# the Debian/Ubuntu branch downloaded FiraCode Nerd Font. Both families are
# installed here so the result matches what the workstation actually had.
#
# The family names below are load-bearing and must not be "normalised":
#   - alacritty asks for `JetBrains Mono Nerd Font Mono` (extra `Mono`)
#   - noctalia's config asks for `Inter`
{ ... }:

{
  flake.nixosModules.home-fonts =
    { pkgs, ... }:
    {
      home-manager.users.alfrest = {
        # Per-user fontconfig cache and `~/.config/fontconfig`. Home Manager
        # enables it here rather than system-wide so font changes roll back
        # with the user's generation.
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
