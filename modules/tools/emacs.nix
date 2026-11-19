# Emacs (GTK3 on X11, not pgtk) with Doom. Nix supplies only the binary and the
# external tools Doom shells out to; elisp packages are Doom's job (straight/
# ELPA), so nothing here goes through `emacsPackages`. Doom itself is a manual
# clone at `~/.config/emacs` (so `doom sync`/`upgrade` can write to it), while
# `$DOOMDIR` is linked out-of-store so edits land in this repo (the path must be
# absolute: inside a flake `./files/...` resolves to a read-only store copy).
{ ... }:

{
  flake.nixosModules.emacs =
    { pkgs, config, ... }:
    let
      home = config.home-manager.users.alfrest.home.homeDirectory;
    in
    {
      home-manager.users.alfrest = {
        home.packages = with pkgs; [
          emacs30-gtk3
          findutils
          aspell
          aspellDicts.en
          libtool
          pkg-config
          nerd-fonts.symbols-only
        ];

        # `doom` lives in the Doom checkout, which nix does not install.
        home.sessionPath = [ "${home}/.config/emacs/bin" ];

        services.emacs = {
          enable = true;
          package = pkgs.emacs30-gtk3;
          startWithUserSession = true;
        };

        # Doom points `server-auth-dir` at its own directory, so the daemon's
        # socket is not where emacsclient looks by default.
        home.sessionVariables.EMACS_SOCKET_NAME = "${home}/.config/emacs/server/server";

        # Doom is a manual clone (see modules/tools/emacs.nix header); don't
        # spawn a vanilla daemon on hosts where it was never installed.
        systemd.user.services.emacs.Unit.ConditionPathExists = "%h/.config/emacs/early-init.el";

        xdg.configFile."doom".source =
          config.home-manager.users.alfrest.lib.file.mkOutOfStoreSymlink
            "${home}/nixos-config/modules/files/doom";
      };
    };
}
