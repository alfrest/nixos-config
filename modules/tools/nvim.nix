# Neovim + LazyVim. `modules/files/nvim` is linked out-of-store (absolute path,
# because a relative path inside a flake would be a read-only store copy) so
# `lazy.nvim` can rewrite `lazy-lock.json` and `:LazyExtras` can update
# `lazyvim.json`; those writes land in this repo and must be committed.
{ ... }:

{
  flake.nixosModules.nvim =
    { pkgs, config, ... }:
    let
      home = config.home-manager.users.alfrest.home.homeDirectory;
    in
    {
      home-manager.users.alfrest = {
        xdg.configFile."nvim".source =
          config.home-manager.users.alfrest.lib.file.mkOutOfStoreSymlink
            "${home}/nixos-config/modules/files/nvim";

        home.packages = with pkgs; [
          neovim
          luarocks
          lazygit
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
