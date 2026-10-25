# Per-user CLI tools. Installed through `home-manager.useUserPackages`, so they
# roll back with the user's generation instead of living in the system profile.
#
# Attribute gotchas: there is no `rust` (use `rustc` + `cargo`) and no `npm`
# (use `nodejs`).
{ ... }:

{
  flake.nixosModules.home-cli-tools =
    { pkgs, ... }:
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
      ];
    };
}
