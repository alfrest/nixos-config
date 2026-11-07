# Per-user CLI tools. Attribute gotchas: there is no `rust` (use `rustc` +
# `cargo`) and no `npm` (use `nodejs`).
{ ... }:

{
  flake.nixosModules.cli-tools =
    { pkgs, pkgs-unstable, ... }:
    {
      home-manager.users.alfrest.home.packages = with pkgs; [
        cmake
        fd
        fzf
        nodejs
        ripgrep
        rustc
        cargo
        unzip
        yazi
        zoxide
        pkgs-unstable.opencode
      ];
    };
}
