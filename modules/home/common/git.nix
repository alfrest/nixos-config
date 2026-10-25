# Git identity and behaviour. With `xdg.enable` on, Home Manager writes
# `~/.config/git/config` (git reads it as well as `~/.gitconfig`).
{ ... }:

{
  flake.nixosModules.home-git =
    { ... }:
    {
      home-manager.users.alfrest.programs.git = {
        enable = true;

        # Home Manager 26.05: single `settings` attrset; dotted keys are INI sections.
        settings = {
          user = {
            name = "alfrest";
            email = "21663772+alfrest@users.noreply.github.com";
          };

          init.defaultBranch = "main";
          pull.rebase = false;
        };
      };
    };
}
