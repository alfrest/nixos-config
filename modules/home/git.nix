# Git identity and behaviour, ported from the Arch `git` role's `gitconfig`.
#
# The source file was a symlinked `~/.gitconfig`; Home Manager generates the
# same content from options, so the file becomes part of the user's generation
# instead of a hand-copied dotfile. With `xdg.enable` on (P1) Home Manager
# writes `~/.config/git/config` rather than `~/.gitconfig` — git reads both.
#
# Installed per-user, so `git` is no longer listed in
# modules/system/packages.nix (P4 of the desktop suite migration).
{ ... }:

{
  flake.nixosModules.home-git =
    { ... }:
    {
      home-manager.users.alfrest.programs.git = {
        enable = true;

        # Home Manager 26.05 replaced `userName`/`userEmail`/`extraConfig` with
        # a single `settings` attrset; dotted keys become INI sections.
        settings = {
          user = {
            name = "alfrest";
            email = "21663772+alfrest@users.noreply.github.com";
          };

          # [init] defaultBranch = main
          init.defaultBranch = "main";

          # [pull] rebase = false
          pull.rebase = false;
        };
      };
    };
}
