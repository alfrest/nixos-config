# Interactive shell: zsh + oh-my-zsh.
#
# With `xdg.enable` on, Home Manager writes the rc files to `~/.config/zsh/` and
# sets `ZDOTDIR` instead of using `~/.zshrc` / `~/.zshenv`.
#
# The system half makes zsh the login shell; without it greetd/tty keeps the
# user's old shell.
{ ... }:

{
  flake.nixosModules.home-zsh =
    { pkgs, lib, ... }:
    {
      # System half: login shell + /etc/shells registration.
      users.users.alfrest.shell = pkgs.zsh;
      programs.zsh.enable = true;

      # oh-my-zsh runs `compinit` itself; the NixOS-wide one would run twice.
      programs.zsh.enableGlobalCompInit = false;

      home-manager.users.alfrest.programs.zsh = {
        enable = true;

        oh-my-zsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [
            "vi-mode"
            "git"
            "fzf"
          ];
        };

        # Non-bundled plugins.
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        # oh-my-zsh's own default; Home Manager would otherwise cap it at 10000.
        history.size = 50000;

        initContent = lib.mkMerge [
          # Order 500: before oh-my-zsh is sourced (at 800). vi-mode reads these
          # when it loads, so they cannot move to the block below.
          (lib.mkOrder 500 ''
            VI_MODE_SET_CURSOR=true
            VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
            DISABLE_UPDATE_PROMPT=true
          '')

          # Order 1000: after oh-my-zsh.
          (lib.mkOrder 1000 ''
            if [[ -n $SSH_CONNECTION ]]; then
              export EDITOR='vim'
            else
              export EDITOR='nvim'
            fi

            eval "$(zoxide init zsh)"
          '')
        ];

        sessionVariables = {
          QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
        };
      };
    };
}
