# Interactive shell: zsh + oh-my-zsh, ported from the Arch `zsh` role.
#
# What the Ansible role did by hand and what replaces it here:
#   - clone oh-my-zsh            -> `programs.zsh.oh-my-zsh.enable`
#   - clone the two custom plugins -> `autosuggestion` / `syntaxHighlighting`
#   - symlink ~/.zshrc           -> generated from `initContent`
#   - template ~/.zshenv         -> `sessionVariables`
#   - `user: shell=/usr/bin/zsh` -> `users.users.alfrest.shell` (system half)
#
# Plugin mapping: `vi-mode`, `git` and `fzf` are bundled with oh-my-zsh, so they
# stay in `oh-my-zsh.plugins`. `zsh-syntax-highlighting` and
# `zsh-autosuggestions` are separate projects; Home Manager has first-class
# options for both (`syntaxHighlighting.enable`, `autosuggestion.enable`) which
# source them from nixpkgs at the right point in the init order, so no
# `programs.zsh.plugins` src juggling is needed.
#
# Dropped on purpose (see plan §1):
#   # removed: vault/bitwarden secrets (out of scope, see plan §1)
#   - GEMINI_API_KEY / GROQ_API_KEY / OPENROUTER_API_KEY (Ansible Vault)
#   - SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/rbw/... (Bitwarden rbw agent)
#   - PATH="$HOME/.config/emacs/bin:$PATH" (no emacs, decision D3)
#
# Path change: because `xdg.enable` is on (P1), Home Manager puts the rc files
# in `~/.config/zsh/` and sets `ZDOTDIR`, instead of the source's `~/.zshrc` /
# `~/.zshenv`. Same content, XDG location.
{ ... }:

{
  flake.nixosModules.home-zsh =
    { pkgs, lib, ... }:
    {
      # System half: make zsh the login shell and register it in /etc/shells.
      # Both are needed — greetd/tty otherwise still starts the user's old shell.
      users.users.alfrest.shell = pkgs.zsh;
      programs.zsh.enable = true;

      # oh-my-zsh runs `compinit` itself; the NixOS-wide one would run it a
      # second time on every shell start.
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

        # The two non-bundled plugins (see header comment).
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        # oh-my-zsh's own default; Home Manager would otherwise drop it to
        # 10000 and silently shrink the scrollback history.
        history.size = 50000;

        initContent = lib.mkMerge [
          # Order 500: before oh-my-zsh is sourced (it is sourced at 800).
          # The vi-mode plugin reads these variables when it loads, so they
          # cannot live in the general block below.
          (lib.mkOrder 500 ''
            VI_MODE_SET_CURSOR=true
            VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
            DISABLE_UPDATE_PROMPT=true
          '')

          # Order 1000: general configuration, after oh-my-zsh.
          (lib.mkOrder 1000 ''
            if [[ -n $SSH_CONNECTION ]]; then
              export EDITOR='vim'
            else
              export EDITOR='nvim'
            fi

            alias tm='tmux attach || tmux'

            eval "$(zoxide init zsh)"
          '')
        ];

        # Was `export QT_QPA_PLATFORMTHEME=...` in the templated ~/.zshenv.
        sessionVariables = {
          QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
        };
      };
    };
}
