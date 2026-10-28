# nix-ld: run foreign ELF binaries (prebuilt downloads, vendor installers,
# unzipped game servers, AppImages) that expect a `/lib64/ld-linux-*.so*`
# interpreter and libraries no Nix package provides.
#
# It is installed as the dynamic loader for non-store binaries only, so
# nixpkgs packages keep their pinned interpreter and libraries — nothing that
# already builds here is affected. Enabling the option also installs the
# module's default library set (zlib, zstd, gcc's libstdc++, curl, openssl,
# libssh, libxml2, util-linux, xz, systemd, ...); add more with
# `programs.nix-ld.libraries = [ ... ];` in the module that needs them (GUI
# libraries belong in `modules/desktop/`, not here).
{ ... }:

{
  flake.nixosModules.nix-ld = {
    programs.nix-ld.enable = true;
  };
}
