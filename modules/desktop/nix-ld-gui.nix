# X11 runtime libraries for unpatched binaries run through nix-ld
# (`programs.nix-ld.libraries` merges across modules; the GUI set belongs here
# per modules/system/nix-ld.nix). Needed by GUI toolkits that dlopen them, and
# by binaries like horizon-launcher linked against a foreign glibc.
{ ... }:

{
  flake.nixosModules.desktop-nix-ld-gui =
    { pkgs, ... }:
    {
      programs.nix-ld.libraries = with pkgs; [
        libxkbcommon
        libxcb
        wayland
        libglvnd
        vulkan-loader

        # Java/JVM games (e.g. Minecraft via foreign launchers): libjsound,
        # libfontmanager and AWT link the ALSA, freetype and X11 stack here.
        alsa-lib
        freetype
        xorg.libX11
        xorg.libXext
        xorg.libXi
        xorg.libXrender
        xorg.libXtst
      ];
    };
}
