# Neovim with the LazyVim setup from the Arch `nvim` role.
#
# The whole `roles/nvim/files/nvim/` tree is vendored verbatim under
# `files/nvim/` (22 files, including the dotfiles `.markdownlint.jsonc`,
# `.neoconf.json` and `.gitignore`; `diff -r` against the source is clean).
#
# It is linked with `mkOutOfStoreSymlink` (decision D12) rather than copied into
# the store, so `~/.config/nvim` is writable: `lazy.nvim` can rewrite
# `lazy-lock.json` and `:LazyExtras` can update `lazyvim.json`. Those writes go
# into this repo and have to be committed — that is the accepted trade-off for
# not patching `lazy.lua`.
#
# The link target is the absolute checkout path because `./files/nvim` is a
# read-only store copy inside a flake.
#
# `neovim` and `lazygit` move here from modules/system/packages.nix (P9). The
# rest are the runtime dependencies the Arch packages happened to provide;
# ripgrep, fd, nodejs and git already come from P3/P4 and are not repeated.
#
# Deliberately not installed: a JDK. `after/ftplugin/java.lua` and
# `google-java-format` need one, but the old box had a global JDK and adding a
# toolchain is a separate decision (plan §10).
{ ... }:

{
  flake.nixosModules.home-nvim =
    { pkgs, config, ... }:
    let
      home = config.home-manager.users.alfrest.home.homeDirectory;
    in
    {
      home-manager.users.alfrest = {
        xdg.configFile."nvim".source =
          config.home-manager.users.alfrest.lib.file.mkOutOfStoreSymlink
            "${home}/nixos-config/modules/home/files/nvim";

        home.packages = with pkgs; [
          neovim
          luarocks
          lazygit
          # LazyVim / tree-sitter build deps.
          gcc
          gnumake
          unzip
          curl
          tree-sitter
          python3
        ];
      };
    };
}
