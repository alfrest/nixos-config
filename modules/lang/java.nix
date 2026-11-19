# Java toolchain for the alfrest user. `jdt-language-server` is the `jdtls`
# command Eglot runs for Doom's (java +lsp).
{ ... }:

{
  flake.nixosModules.java =
    { pkgs, ... }:
    {
      home-manager.users.alfrest.home.packages = with pkgs; [
        openjdk25
        jdt-language-server
      ];
    };
}
