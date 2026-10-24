# Per-user CLI tools, ported from the Arch `cli_tools` role.
#
# They live in the user's Home Manager profile (installed through
# `users.users.alfrest.packages`, because `home-manager.useUserPackages = true`)
# rather than in `environment.systemPackages`: they roll back with the user's
# generation and do not pollute the system profile.
#
# Package mapping from the source role:
#   Arch `rust`       -> `rustc` + `cargo` (there is no `rust` attribute)
#   Arch `npm`        -> `nodejs` (ships npm; there is no `npm` attribute)
#   AUR `sesh-bin`    -> `sesh`
# `fd` is simply `fd` here, so the old `/usr/local/bin/fd` symlink workaround
# for Debian-style `fdfind` disappears entirely.
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
        wl-clipboard
        yazi
        zoxide
        sesh
      ];
    };
}
