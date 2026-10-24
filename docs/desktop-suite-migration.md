# Dotfiles migration plan — Ansible (Arch `dsk`) → NixOS `vm`

Status: **planning complete, no code written yet**
Created: 2026-10-24
Source of truth: `https://github.com/alfrest/ansible-dotfiles` at commit `d75c36b` ("update vault")
Target repo: `/home/alfrest/nixos-config` (dendritic NixOS flake, host `vm`)

This file is written so that **any future session can pick up the work at any phase**
without needing the session that wrote it. Read section 0 and the progress table (section 6)
before touching anything.

---

## 0. How a session uses this file

1. Read sections 1–4 (invariants, scope, decisions, mapping). Do not re-litigate them
   unless the user explicitly asks.
2. Pick the **first phase in section 5 whose checkbox status is `todo`** and whose
   prerequisites are `done`. Do one phase per session/commit unless the user says otherwise.
3. Follow that phase's steps exactly, run its verification block, and only then mark it
   `done` in the progress table (section 6) with the commit hash and date.
4. If a verification step fails, stop. Do **not** mark the phase done and do **not**
   start the next phase. Record the failure in section 6 under "blockers".
5. One commit per phase. Commit style follows the existing log:
   `feat(home): ...`, `feat(desktop): ...`, `feat(flake): ...`.

Phases are ordered so each one is independently buildable, independently revertible, and
verifiable without needing the next one. Phases 1–9 are safe on a headless machine;
phases 10–13 touch graphics and login and carry the real lockout risk.

### Branch status

Branch **`feat/desktop-suite`** was created from `main` and is the branch this plan lives
on. Baseline verified before any change (see P0). Everything below happens on that
branch, one commit per phase. `main` stays a known-good, headless-safe configuration
until P15 passes.

To check you are on the right branch:

```sh
cd /home/alfrest/nixos-config
git branch --show-current        # feat/desktop-suite
```

---

## 1. Ground truth and scope

### What is being migrated

The **Arch workstation** profile only (`inventories/local/host_vars/dsk.yml` →
`machine_profile: dsk` → `desktop` + `dev`):

```
dsk     → desktop, dev
desktop → gui, gtk, tuigreet, niri, noctalia
gui     → base, fonts, alacritty
base    → xdg_user_dirs, cli_tools, git, zsh
dev     → base, herdr, nvim, tmux
```

Leaf roles in scope: `xdg_user_dirs`, `cli_tools`, `git`, `zsh`, `fonts`, `alacritty`,
`gtk`, `tuigreet`, `niri`, `noctalia`, `herdr`, `nvim`, `tmux`.

### Explicitly out of scope (do not migrate)

| Source | Why |
| --- | --- |
| `roles/docker`, `storage`, `immich`, `nextcloud`, `servarr`, `samba`, `ums`, `rclone-webdav`, `srv`, `srv_services`, `homelab.yml`, `inventories/homelab/` | Server configuration. |
| `inventories/*/group_vars/all/vault.yml`, `scripts/ansible_vault_pass.sh`, `ansible_become_pass` | Ansible Vault secrets. |
| `zshenv.j2` lines exporting `GEMINI_API_KEY`, `GROQ_API_KEY`, `OPENROUTER_API_KEY` | Vault secrets. Leave a commented `TODO` where they would go. |
| `zshrc` line `export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/rbw/ssh-agent-socket"` | Bitwarden `rbw` agent. Drop it; do not install `rbw`. |
| `arch-distrobox` profile, `yay`, `arch-distrobox` role, `aur_builder` user | Arch-only packaging mechanics; replaced by nixpkgs. |
| `waybar` role | Present in the source repo but **not reachable from any profile** (its own meta says so). Noctalia is the bar. Deferred, not deleted from the plan space. |
| `roles/nvim/tasks`' package list beyond `neovim`/`luarocks` | Replaced by explicit runtime deps (see P9). |

### Known gap in the source repo (must be handled, do not copy blindly)

`roles/tuigreet/templates/config.toml.j2` has `command = "tuigreet --remember
--remember-session"` with no `--cmd`. tuigreet therefore launches the login shell, not
niri. The documented parity target is "greetd → niri", so the NixOS version **will** add
`--cmd niri-session`. This is a deliberate, documented deviation (P12).

---

## 2. Non-negotiable repo rules (from `AGENTS.md`)

- Dendritic pattern: every file under `modules/` is a flake-parts module that declares
  **exactly one** `flake.nixosModules.<name>`. Never `import` one feature module from another.
- A new module is activated only by adding `self.nixosModules.<name>` to the list in
  `modules/hosts/vm/default.nix`.
- Flakes only see **git-tracked** files: `git add` new files before `nix flake check` /
  `nixos-rebuild`, or they silently do not exist.
- Never change `system.stateVersion` / `home.stateVersion` (both `"26.05"`).
- Never edit `modules/hosts/vm/hardware-configuration.nix` (generated).
- Always target `.#vm`.
- `sudo` needs a password: ask the user to run `sudo nixos-rebuild switch --flake .#vm`.
  Dry-build and evaluation do not need sudo.

### Mandatory verification after every phase

```sh
cd /home/alfrest/nixos-config

# 1. syntax
find . -name '*.nix' -not -path './.git/*' -exec nix-instantiate --parse {} + >/dev/null

# 2. flake evaluation (nixosConfigurations.vm)
nix flake check

# 3. evaluate + build everything without activating
nixos-rebuild dry-build --flake .#vm

# 4. prove the Home Manager generation evaluates (not just NixOS)
nix eval --raw .#nixosConfigurations.vm.config.home-manager.users.alfrest.home.activationPackage
```

Never report success on a non-zero exit. Then run the phase's manual runtime checks
(they require the user to run `sudo nixos-rebuild switch` first).

### Secrets policy for the whole migration

Nothing from the vault, nothing from Bitwarden, no API keys, no passwords, no SSH agent
socket. If a future session finds itself needing one, stop and ask the user — do not
invent a placeholder secret mechanism (agenix/sops) as part of this migration.

---

## 3. Decisions already taken (do not re-open without the user)

| # | Decision | Evidence / consequence |
| --- | --- | --- |
| D1 | The `vm` **has a graphical display** (user confirmed). Graphics stack is enabled in P10. | `hardware.graphics.enable = true`; verify `/dev/dri` first. |
| D2 | **Full parity**: greetd + tuigreet logs into niri. | Lockout risk mitigated by OpenSSH (already enabled) + generation rollback; see P12. |
| D3 | **No emacs**, and its niri binds are removed. | `Mod+E` and `PATH=$HOME/.config/emacs/bin` are dropped. |
| D4 | **Zen browser is included** via the community flake, **playerctl is included**, and both keep their binds. | `inputs.zen-browser.url = "github:0xc000022070/zen-browser-flake"`, package `zen-browser` (`packages.<system>.default`); `pkgs.playerctl`. |
| D5 | Noctalia is **`pkgs.noctalia`** (5.x), not `pkgs.noctalia-shell` (4.7.6). | The old config drives it with `noctalia msg ...`; nixpkgs `noctalia` installs a `noctalia` binary, `noctalia-shell` installs `noctalia-shell`. |
| D6 | Noctalia gets a **NixOS-native wallpaper**; the Arch wallpaper package does not exist here. | `archlinux-wallpaper(s)` are not in nixpkgs; use a `pkgs.nixos-artwork.wallpapers.*` path. Pick with the user at P11. |
| D7 | niri is configured with **Home Manager `xdg.configFile."niri/config.kdl"`**, not `programs.niri`. | Home Manager 26.05 has **no** `programs.niri` and **no** `programs.noctalia` (verified by evaluating the locked input's options). The KDL file is generated from a Nix string so store paths can be interpolated. |
| D8 | Alacritty theme comes from `pkgs.alacritty-theme`, imported by absolute store path. | Verified: `${pkgs.alacritty-theme}/share/alacritty-theme/vscode.toml` exists. |
| D9 | zsh goes through Home Manager (`programs.zsh`), not a hand-written `zshrc`. | Same plugins/theme/aliases, declared as options. |
| D10 | GTK settings go through `gtk.*` (Home Manager) which writes dconf, replacing the `community.general.dconf` task. | |
| D11 | `waybar` stays out (see scope), `arch-distrobox`/`yay`/`aur_builder` are not recreated. | |

---

## 4. Source → target mapping

Target layout (new directory `modules/desktop/` for system-level desktop pieces,
`modules/home/` for per-user config). Every row = one new file exposing exactly one
`flake.nixosModules.<name>`.

| Phase | Source role / file | New module file | Module name |
| --- | --- | --- | --- |
| P1 | `roles/xdg_user_dirs` | `modules/home/xdg-user-dirs.nix` | `home-xdg-user-dirs` |
| P2 | `roles/fonts` | `modules/home/fonts.nix` | `home-fonts` |
| P3 | `roles/cli_tools` | `modules/home/cli-tools.nix` | `home-cli-tools` |
| P4 | `roles/git`, `roles/zsh` | `modules/home/git.nix`, `modules/home/zsh.nix` | `home-git`, `home-zsh` |
| P5 | `roles/gtk` | `modules/home/gtk.nix` | `home-gtk` |
| P6 | `roles/alacritty` | `modules/home/alacritty.nix` | `home-alacritty` |
| P7 | `roles/tmux` | `modules/home/tmux.nix` | `home-tmux` |
| P8 | `roles/herdr` | `modules/home/herdr.nix` | `home-herdr` |
| P9 | `roles/nvim` | `modules/home/nvim.nix` + `modules/home/files/nvim/**` (vendored tree) | `home-nvim` |
| P10 | `roles/niri` (system half) | `modules/desktop/graphics.nix` | `desktop-graphics` |
| P11 | `roles/niri` (config half) | `modules/desktop/niri.nix` | `desktop-niri` |
| P12 | `roles/noctalia` | `modules/desktop/noctalia.nix` | `desktop-noctalia` |
| P13 | `roles/tuigreet` | `modules/desktop/greetd.nix` | `desktop-greetd` |
| P14 | niri binds → zen/playerctl | `modules/home/media.nix` (or fold into P11) | `home-media` |

Note the phase numbers below are shifted by one relative to the original sketch:
P10 = graphics prerequisites, P11 = niri, P12 = noctalia, P13 = greetd, P14 = final audit.

Vendored data lives under `modules/home/files/` (contains no `.nix` files, so `import-tree`
ignores it). The niri/noctalia config text can either be a `builtins.readFile ./files/...`
with `replaceStrings`, or a Nix multi-line string. **Prefer `readFile` + interpolation**:
it keeps the original KDL/TOML readable and diffable, which is what makes verification easy.

---

## 5. Phases

Legend: `[ ]` todo, `[x]` done, `[~]` in progress, `[!]` blocked.

---

### [x] P0 — Branch + baseline (done 2026-10-24)

**Goal:** a branch and a recorded green baseline.

Steps:
1. `git switch -c feat/desktop-suite` — **done**, branch created from `main`.
2. Mandatory verification on the untouched tree — **done, all green**:
   - `nix-instantiate --parse` over every `*.nix`: OK
   - `nix flake check`: `all checks passed!`
   - `nixos-rebuild dry-build --flake .#vm`: exit 0
3. Generation / boot-entry recording: deferred to the user (needs `sudo bootctl list`);
   not a blocker for P1.

Verification: all commands exited 0.
Rollback: `git switch main`.

---

### [ ] P1 — XDG user dirs + screenshots dir

**Goal:** `~/Desktop`, `~/Documents`, `~/Downloads`, `~/Pictures`, `~/Videos`, `~/Music`,
plus `~/Pictures/Screenshots` because the niri config points there.

New file `modules/home/xdg-user-dirs.nix`:

```nix
{ ... }:
{
  flake.nixosModules.home-xdg-user-dirs =
    { ... }:
    {
      home-manager.users.alfrest = {
        xdg.enable = true;                       # also sets XDG_CONFIG_HOME etc.
        xdg.userDirs = {
          enable = true;
          createDirectories = true;
          # defaults match the Arch setup (Desktop, Documents, Downloads, ...)
        };
        # niri: screenshot-path "~/Pictures/Screenshots/..."
        home.file."Pictures/Screenshots/.keep".text = "";
      };
    };
}
```

Add `self.nixosModules.home-xdg-user-dirs` to `modules/hosts/vm/default.nix`.

Steps: create file → add to host list → `git add` → verification block → ask user to
`sudo nixos-rebuild switch --flake .#vm`.

Runtime checks:
```sh
xdg-user-dir PICTURES          # /home/alfrest/Pictures
ls -d ~/Pictures/Screenshots
echo $XDG_CONFIG_HOME          # /home/alfrest/.config
```

Gotchas: `xdg-user-dirs` package is pulled in automatically by the HM module; do not add
it to `environment.systemPackages`. If the old `~/.config/user-dirs.dirs` already exists
from another distro, HM will back it up as `*.hm-backup` (see `home-manager.backupFileExtension`).

Rollback: remove module from host list, rebuild, `git revert`.

---

### [ ] P2 — Fonts

**Goal:** Inter, Source Serif, JetBrains Mono Nerd Font, FiraCode Nerd Font; fontconfig on.

Source: `roles/fonts/tasks/main.yml` (Arch branch installs `inter-font`,
`adobe-source-serif-fonts`, `ttf-jetbrains-mono-nerd`; non-Arch branch downloads
FiraCode Nerd Font — include both families for parity).

New file `modules/home/fonts.nix`:

```nix
{ pkgs, ... }:
{
  flake.nixosModules.home-fonts =
    { ... }:
    {
      home-manager.users.alfrest = {
        fonts.fontconfig.enable = true;
        home.packages = with pkgs; [
          inter
          source-serif
          nerd-fonts.jetbrains-mono
          nerd-fonts.fira-code
        ];
      };
    };
}
```

All four attribute names were verified against the locked nixpkgs.

Runtime checks:
```sh
fc-list | grep -i "JetBrainsMono Nerd Font" | head -3
fc-list | grep -i "FiraCode Nerd Font" | head -3
fc-list | grep -i "^.*Inter" | head -3
fc-match "JetBrains Mono Nerd Font Mono"     # must not fall back to DejaVu
```

Gotchas: the alacritty family string is `JetBrains Mono Nerd Font Mono` (with the extra
`Mono`), the waybar CSS uses `JetBrainsMono Nerd Font Propo`, noctalia uses `Inter`.
Do not "normalise" these names — they are what the old machine actually used.

Rollback: drop module, rebuild.

---

### [ ] P3 — CLI tools

**Goal:** the `cli_tools` package set, from nixpkgs, per-user.

Source list: `cmake fd fzf npm ripgrep rust unzip wl-clipboard yazi zoxide` + AUR `sesh-bin`.
nixpkgs equivalents (verified): `cmake`, `fd`, `fzf`, `nodejs` (provides `npm`),
`ripgrep`, `rustc`+`cargo`, `unzip`, `wl-clipboard`, `yazi`, `zoxide`, `sesh`.

New file `modules/home/cli-tools.nix`:

```nix
{ pkgs, ... }:
{
  flake.nixosModules.home-cli-tools =
    { ... }:
    {
      home-manager.users.alfrest.home.packages = with pkgs; [
        cmake fd fzf nodejs ripgrep rustc cargo unzip wl-clipboard yazi zoxide sesh
      ];
    };
}
```

Also in this phase: remove the now-duplicated user tools from
`modules/system/packages.nix` (keep `vim`, `wget`, `git`? — `git` moves to P4's HM
module; `neovim`/`lazygit` to P9; `herdr` stays system-side or moves to P8 — decide in
that phase and record it here). Do not remove `opencode` (user's active tool, from
`pkgs-unstable`).

Rationale to record in the module comment: user tools in the per-user profile
(`home-manager.useUserPackages = true` → `/etc/profiles/per-user/alfrest`) so they roll
back with the user's generation and do not pollute the system profile.

Runtime checks:
```sh
for c in cmake fd fzf node npm rg cargo rustc unzip wl-copy yazi zoxide sesh; do
  command -v "$c" >/dev/null && echo "ok $c" || echo "MISSING $c"
done
yazi --version; zoxide --version; sesh --version
```

Gotchas: `fd` is `fd`, not Debian's `fdfind` — the old `cli_tools` role created a
`/usr/local/bin/fd` symlink on apt systems; **that whole workaround disappears here**.
`rust` in Arch = `rustc` + `cargo` in nixpkgs; `npm` comes from `nodejs`, there is no
`npm` attribute.

Rollback: revert, rebuild; packages disappear from the per-user profile.

---

### [ ] P4 — Git + Zsh

**Goal:** same git identity/behaviour, same interactive shell with oh-my-zsh, the four
plugins, vi-mode, `EDITOR` logic, `tm` alias, zoxide init.

Source: `roles/git/files/gitconfig`, `roles/zsh/files/zshrc`, `roles/zsh/tasks/main.yml`.

`modules/home/git.nix`:

```nix
{ ... }:
{
  flake.nixosModules.home-git =
    { ... }:
    {
      home-manager.users.alfrest.programs.git = {
        enable = true;
        userName = "alfrest";
        userEmail = "21663772+alfrest@users.noreply.github.com";
        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = false;            # old: [pull] rebase = false
        };
      };
    };
}
```

`modules/home/zsh.nix` (sketch — keep the comments explaining what was dropped):

```nix
{ pkgs, ... }:
{
  flake.nixosModules.home-zsh =
    { ... }:
    {
      users.users.alfrest.shell = pkgs.zsh;          # system half: login shell
      programs.zsh.enable = true;                    # NixOS half: /etc/shells, completion
      home-manager.users.alfrest = {
        programs.zsh = {
          enable = true;
          oh-my-zsh = {
            enable = true;
            theme = "robbyrussell";
            plugins = [ "vi-mode" "git" "fzf" ];
          };
          # third-party plugins are HM packages, not oh-my-zsh dirs:
          plugins = [
            { name = "zsh-syntax-highlighting"; src = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting"; }
            { name = "zsh-autosuggestions";     src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions"; }
          ];
          initExtra = ''
            # vi-mode (was VI_MODE_* in the ansible zshrc)
            VI_MODE_SET_CURSOR=true
            VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
            DISABLE_UPDATE_PROMPT=true

            if [[ -n $SSH_CONNECTION ]]; then
              export EDITOR='vim'
            else
              export EDITOR='nvim'
            fi
            alias tm='tmux attach || tmux'
            eval "$(zoxide init zsh)"
          '';
          sessionVariables = {
            QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
          };
        };
      };
    };
}
```

Notes / gotchas:
- `oh-my-zsh` is provided by HM (`programs.zsh.oh-my-zsh`, verified present) — do **not**
  clone it with a git task; the old clones exist only because Arch had no declarative path.
- `vi-mode` and `git` are plugins **bundled with** oh-my-zsh (`oh-my-zsh.plugins`).
  `fzf` is also bundled. `zsh-syntax-highlighting` / `zsh-autosuggestions` are separate
  projects and belong in `programs.zsh.plugins` (verify the `src` subdirectory at
  implementation time with `ls $(nix build ...)/share/...`; HM expects the dir that
  contains the `.zsh` file).
- `DISABLE_UPDATE_PROMPT=true` only matters if oh-my-zsh self-update is enabled; keep it
  harmless.
- **Dropped on purpose:** `PATH="$HOME/.config/emacs/bin:$PATH"` (no emacs),
  `export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/rbw/..."` (Bitwarden),
  `GEMINI_API_KEY`/`GROQ_API_KEY`/`OPENROUTER_API_KEY`. Leave one comment block
  `# removed: vault/bitwarden secrets (out of scope, see plan §1)`.
- Set the login shell via `users.users.alfrest.shell` **and** `programs.zsh.enable`, or
  greetd/tty may still start bash.
- Do not set `programs.zsh.enableGlobalCompInit` twice.

Runtime checks:
```sh
getent passwd alfrest | cut -d: -f7     # /etc/profiles/per-user/... or /run/current-system/sw/bin/zsh
zsh -ic 'echo $ZSH_THEME; echo $EDITOR; alias tm'
zsh -ic 'zoxide --version'
git config --get user.name; git config --get init.defaultBranch
```
Interactive: prefix/vi-mode keys, autosuggestion rendering, syntax highlighting.

Rollback: revert; `chsh` is not needed because the shell is declared.

---

### [ ] P5 — GTK theme + dconf

**Goal:** `adw-gtk3-dark`, prefer-dark, same icon/font defaults.

Source: `roles/gtk/tasks/main.yml` (installs `gnome-themes-extra`, `adw-gtk-theme`,
`python-psutil`, `python-gobject`; dconf sets `gtk-theme=adw-gtk3-dark`,
`color-scheme=prefer-dark`).

New file `modules/home/gtk.nix`:

```nix
{ pkgs, ... }:
{
  flake.nixosModules.home-gtk =
    { ... }:
    {
      home-manager.users.alfrest = {
        gtk = {
          enable = true;
          theme = { name = "adw-gtk3-dark"; package = pkgs.adw-gtk3; };
          colorScheme = "dark";
          iconTheme = { name = "Adwaita"; package = pkgs.adwaita-icon-theme; };
        };
        home.packages = with pkgs; [ gnome-themes-extra adw-gtk3 ];
      };
    };
}
```

`python-psutil` / `python-gobject` were Arch runtime deps for the shell, not settings.
Only add them if Noctalia actually fails without them (check at P12); note the decision.

Runtime checks:
```sh
gsettings get org.gnome.desktop.interface gtk-theme     # 'adw-gtk3-dark'
gsettings get org.gnome.desktop.interface color-scheme  # 'prefer-dark'
```

Gotchas: `gtk.enable` writes `~/.config/gtk-3.0/settings.ini` **and** dconf; do not also
set `environment.sessionVariables.GTK_THEME`. `gtk4` needs `gtk.gtk4.theme` only if an
app misbehaves — start without it.

Rollback: revert (dconf keys revert on the next HM activation).

---

### [ ] P6 — Alacritty

**Goal:** same font, size 12, vscode theme, `Ctrl+Backspace` → `\x17`.

Source: `roles/alacritty/files/alacritty.toml`.

New file `modules/home/alacritty.nix`:

```nix
{ pkgs, ... }:
{
  flake.nixosModules.home-alacritty =
    { ... }:
    {
      home-manager.users.alfrest.programs.alacritty = {
        enable = true;
        settings = {
          general.import = [ "${pkgs.alacritty-theme}/share/alacritty-theme/vscode.toml" ];
          keyboard.bindings = [
            { key = "Backspace"; mods = "Control"; chars = "\u0017"; }
          ];
          font = {
            normal = { family = "JetBrains Mono Nerd Font Mono"; style = "Regular"; };
            bold   = { family = "JetBrains Mono Nerd Font Mono"; style = "Bold"; };
            italic = { family = "JetBrains Mono Nerd Font Mono"; style = "Italic"; };
            size = 12;
          };
        };
      };
    };
}
```

Path verified: `pkgs.alacritty-theme` installs `share/alacritty-theme/vscode.toml`.
This replaces the old `git clone` of `alacritty-theme` into `~/.config/alacritty/themes`
— no clone, no stale checkout.

Runtime checks (inside the graphical session, or `alacritty` on any display):
```sh
alacritty --version
alacritty msg config font.size        # 12 (needs a running instance)
```
Visual: dark vscode palette, `Ctrl+Backspace` deletes a word in the shell.

Gotcha: alacritty logs a warning if `general.import` points at a directory-like path —
the exact file path above is the correct form. The old relative
`~/.config/alacritty/themes/themes/vscode.toml` must **not** be copied.

Rollback: revert.

---

### [ ] P7 — tmux

**Goal:** identical keybinds/theme/plugins, `M-Space` prefix, TPM plugins declared
declaratively instead of cloned at first start.

Source: `roles/tmux/files/tmux.conf` (full file in appendix A).

New file `modules/home/tmux.nix` using `programs.tmux` (options verified present):

```nix
{ pkgs, ... }:
{
  flake.nixosModules.home-tmux =
    { ... }:
    {
      home-manager.users.alfrest.programs.tmux = {
        enable = true;
        terminal = "tmux-256color";
        historyLimit = 50000;
        escapeTime = 0;
        baseIndex = 1;
        keyMode = "vi";
        mouse = true;
        plugins = with pkgs.tmuxPlugins; [ sensible vim-tmux-navigator ];
        extraConfig = ''
          # ...everything from tmux.conf sections 1-8...
        '';
      };
    };
}
```

Mapping rules for the move:
- `unbind C-b`, `set -g prefix M-Space`, `bind M-Space send-prefix` → keep in `extraConfig`.
- `base-index`/`pane-base-index`/`history-limit`/`escape-time`/`mouse`/`mode-keys`/
  `default-terminal` → use the HM options above; remove them from `extraConfig`.
- `@plugin` lines and the TPM bootstrap `if "test ! -d ..."` block → **delete**; HM
  generates the plugin loader.
- `@vim_navigator_mapping_{left,right,up,down}` → keep (they configure the HM-installed plugin).
- Everything else (key tables `tab-keys`/`window-keys`/`session-keys`, copy-mode binds,
  Dark+ palette block, status line) → verbatim into `extraConfig`.
- `bind r source-file ~/.config/tmux/tmux.conf` → HM writes exactly that path, so it works.

Runtime checks:
```sh
tmux -V
tmux show -g prefix          # M-Space
tmux show -g base-index      # 1
tmux list-keys -T window-keys | head
# in a session: prefix+ TAB / w / s tables, Alt+1..0 window switch, prefix+r reload
```

Gotcha: `sensible` sets `escape-time`/`history-limit` itself and may conflict with the
options above; HM orders `plugins` after `extraConfig`. If a value is clobbered, set it in
`extraConfig` explicitly (HM appends it last after plugins).

Rollback: revert; `~/.config/tmux/tmux.conf` is HM-owned (backed up as `hm-backup` the
first time).

---

### [ ] P8 — herdr config

**Goal:** the existing `herdr` package gets its config file (the old repo symlinked
`~/.config/herdr/config.toml`; the NixOS config installs the binary from
`pkgs-unstable` but no config today).

Source: `roles/herdr/files/config.toml` (prefix `alt+space`, Dark+ palette, `ui.accent`).

New file `modules/home/herdr.nix`:

```nix
{ ... }:
{
  flake.nixosModules.home-herdr =
    { ... }:
    {
      home-manager.users.alfrest.xdg.configFile."herdr/config.toml".source =
        ./files/herdr/config.toml;
    };
}
```

Copy the TOML verbatim to `modules/home/files/herdr/config.toml`; keep every comment
(they explain which herdr token is a foreground vs background — that knowledge is not
recoverable from the file alone).

Note: this is the first module with a `files/` sibling; `import-tree` will not descend
into it because there are no `.nix` files there. Confirm with `nix flake check` anyway.

Runtime checks:
```sh
ls -l ~/.config/herdr/config.toml
herdr --version
herdr server reload-config      # inside a session
```
Visual: sidebar headers grey-on-dark, not black-on-black; accent `#4DA6FF`.

Gotcha: the existing `modules/system/packages.nix` already pulls
`pkgs-unstable.herdr`. Keep the package there for now (P14 dedupe decision) — do not add a
second copy in `home.packages`, that would create two different store paths.

Rollback: revert; config file is removed on the next HM activation.

---

### [ ] P9 — Neovim (vendored LazyVim)

**Goal:** the same LazyVim setup, pins and custom plugin files.

Source: `roles/nvim/files/nvim/**` (LazyVim starter + `lazy-lock.json` + `lazyvim.json`
with 7 extras + `lua/plugins/*.lua`: avante, colorscheme, formatting, markdown, neogit,
nvim-tmux-navigator, yazi, `after/ftplugin/java.lua`, `.markdownlint.jsonc`,
`.neoconf.json`, `stylua.toml`; upstream `LICENSE`/`README.md`/`.gitignore`/`example.lua`
are kept on purpose per the source `AGENTS.md`).

Steps:
1. Copy the tree to `modules/home/files/nvim/` **including** dotfiles (`.markdownlint.jsonc`,
   `.neoconf.json`, `.gitignore`). Verify with `find modules/home/files/nvim -type f | wc -l`
   against the source count and diff both trees.
2. New file `modules/home/nvim.nix`:

```nix
{ pkgs, ... }:
{
  flake.nixosModules.home-nvim =
    { ... }:
    {
      home-manager.users.alfrest = {
        xdg.configFile."nvim".source = ./files/nvim;
        home.packages = with pkgs; [
          neovim luarocks
          # LazyVim runtime deps the Arch packages happened to provide:
          ripgrep fd lazygit gcc gnumake unzip curl git
          nodejs python3 tree-sitter
        ];
      };
    };
}
```

3. **Lockfile write problem (must be solved in this phase).** HM links the config
   directory read-only from the Nix store; `lazy.nvim` tries to rewrite
   `lazy-lock.json` inside it and `:LazyExtras` writes `lazyvim.json`. Pick one:
   - **(recommended)** patch `modules/home/files/nvim/lua/config/lazy.lua` to put the
     lockfile in the state dir:
     ```lua
     lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
     ```
     and accept that `lazyvim.json` extras are edited in the repo, not via the UI.
   - or `mkOutOfStoreSymlink` to the live checkout (writable, but hardcodes
     `/home/alfrest/nixos-config`, and edits bypass git until committed).
   Record the choice in the module comment.

Runtime checks:
```sh
nvim --headless "+Lazy! sync" +qa            # plugins install from the lockfile
nvim --headless "+checkhealth lazyvim" +qa   # inspect only
nvim --headless "+lua print(vim.fn.stdpath('config'))" +qa
```
Visual: `:Lazy` shows every plugin as pinned/matching `lazy-lock.json`; `:checkhealth`
passes for rg/fd/node/git; colorscheme `vscode` loads; `:MarkdownPreview`-adjacent
markdownlint path resolves to the config dir.

Gotchas:
- `avante.nvim` reads `GROQ_API_KEY` at runtime. It is **not** provided (secret, out of
  scope) — the plugin will be configured but degrade. Do not add the key.
- `lazy-lock.json` pins plugins; a `nix flake update` does not touch it. Leave as is.
- `after/ftplugin/java.lua` + `google-java-format` need a JDK; the old Arch box had one
  globally. Add `jdk21` only if the user asks — note it as a deferred item, do not
  silently install a toolchain.
- `.gitignore` inside the vendored tree is for the LazyVim project, not for this repo;
  do not add it to the repo root.

Rollback: revert. `~/.config/nvim` becomes a backup on first activation (was absent).

---

### [ ] P10 — Graphics prerequisites (no login change yet)

**Goal:** make a Wayland session *possible* on this VM, without touching getty/greetd.
Nothing here is user-visible; it is the foundation for P11–P13.

New file `modules/desktop/graphics.nix`:

```nix
{ pkgs, ... }:
{
  flake.nixosModules.desktop-graphics =
    { ... }:
    {
      hardware.graphics.enable = true;            # Mesa/EGL/GBM (llvmpipe included)
      services.gnome.gnome-keyring.enable = true; # greetd PAM picks this up (P13)
      security.polkit.enable = true;              # default, stated for clarity

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
        ];
        config.niri.default = [ "gnome" "gtk" ];
      };

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        # Only if the VM has no working virgl and niri fails to create a GL context:
        # LIBGL_ALWAYS_SOFTWARE = "1";
      };
    };
}
```

Steps:
1. Verify the VM exposes DRM **before** writing the module:
   `ls -l /dev/dri` (expect `card0`/`renderD128`). If missing, stop: the QEMU domain
   needs `virtio-gpu` (+ `virgl=on` or `gl=on`) attached on the host side. Record it as a
   blocker; do not fake it with `LIBGL_ALWAYS_SOFTWARE` alone.
2. Create the module, add to host list, `git add`, verification block, ask for rebuild.

Runtime checks (`nix shell nixpkgs#mesa-demos -c eglinfo` or):
```sh
ls -l /dev/dri
nix shell nixpkgs#vulkan-tools -c vulkaninfo --summary | head -20   # optional
journalctl -b -p warning --no-pager | grep -iE "drm|gpu|mesa" | head
```

Gotchas: `hardware.graphics.enable` is the 26.05 name (`hardware.opengl` is gone).
Do not enable `services.xserver` — niri is not an X11 session, and the old config used
`xwayland-satellite` instead of an X server. Adding `services.xserver` would start a
second display stack and can steal the TTY.

Rollback: revert; no runtime state changes.

---

### [ ] P11 — niri

**Goal:** the exact `config.kdl` behaviour, generated by Nix so binaries are absolute
store paths. This phase still does **not** change how you log in; you start niri manually.

New file `modules/desktop/niri.nix` + `modules/desktop/files/niri/config.kdl`
(the source `config.kdl.j2` with the host-specific output block made a Nix option and the
package names replaced by placeholders — see below).

```nix
{ pkgs, ... }:
let
  # QEMU/VM: leave the output auto-configured. The old workstation pinned
  # `output "DP-2" { mode "2560x1440@239.958" scale 1 }`; that block is intentionally
  # absent unless `output` is set below.
  outputBlock = "";
  config = builtins.replaceStrings
    [ "@NOCTALIA@" "@POLKIT@" "@TERMINAL@" "@BROWSER@" "@PLAYERCTL@" "@OUTPUT@" ]
    [ "${pkgs.noctalia}/bin/noctalia"
      "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
      "${pkgs.alacritty}/bin/alacritty"
      "${pkgs.zen-browser}/bin/zen"
      "${pkgs.playerctl}/bin/playerctl"
      outputBlock
    ]
    (builtins.readFile ./files/niri/config.kdl);
in
{
  flake.nixosModules.desktop-niri =
    { ... }:
    {
      environment.systemPackages = with pkgs; [
        niri
        xwayland-satellite
        alacritty
        kdePackages.polkit-kde-agent-1
        playerctl
      ];

      home-manager.users.alfrest = {
        xdg.configFile."niri/config.kdl".text = config;
        # niri-session is provided by pkgs.niri; greetd uses it in P13.
      };
    };
}
```

Content changes versus the source `config.kdl.j2` (all deliberate):
1. `spawn-sh-at-startup "/usr/lib/polkit-kde-authentication-agent-1 &"` → absolute path
   from the placeholder (same agent, correct store path; NixOS hosts it in `libexec`).
2. `spawn-sh-at-startup "noctalia"` → absolute path (P12 installs the package; until then
   this spawn fails harmlessly and logs — acceptable ordering, but if you prefer a clean
   P11, comment the line and un-comment it in P12).
3. `Mod+Return ... { spawn "alacritty"; }` → absolute path.
4. `Mod+B ... { spawn "zen-browser"; }` → `${pkgs.zen-browser}/bin/zen`; **requires P14's
   flake input first**, so either land P14 before P11 or temporarily bind a placeholder.
   Recommended order change: do **P14 (zen input + playerctl package) immediately before
   P11**. Record whichever order you take in the progress table.
5. **Remove** `Mod+E { spawn-sh "emacsclient ..."; }` entirely (D3).
6. `Mod+O`, workspaces, column ops, mouse/touchpad, `gestures.hot-corners off`,
   `prefer-no-csd`, `animations`, `input { keyboard { xkb { layout "se" } numlock } ... }`:
   copy verbatim.
7. `screenshot-path "~/Pictures/Screenshots/..."` stays; P1 creates the directory.
8. Output block: omitted for the VM. If the VM advertises a fixed resolution and the user
   wants it, add `output "Virtual-1" { mode "..." }` later — do **not** copy `DP-2`.
9. `Mod+M`, `Mod+C`, etc. all unchanged.

Runtime checks (from a TTY, after rebuild — no login manager yet):
```sh
ls ~/.config/niri/config.kdl
niri validate                      # or: niri --check (version-dependent); both read the file
niri-session -l 2>&1 | head        # list sessions, does not start one
# start it for real on tty2 and watch the journal:
niri-session
journalctl --user -b -n 100 --no-pager | tail -50
```
Visual: `Mod+O` overview, `Mod+Q` closes, `Mod+1..9` workspaces, `Mod+Return` opens
alacritty, screenshot on `Print` lands in `~/Pictures/Screenshots`, volume keys reach
noctalia *once P12 is in* (before that they do nothing — expected).

Gotchas:
- niri is **not** an HM `programs.*`; if a future niri release adds a HM module, do not
  switch to it mid-migration.
- `niri validate`/`niri --check` has no `--config` flag in all versions; run it as the
  user and let it read `$XDG_CONFIG_HOME/niri/config.kdl`. If the subcommand is missing,
  rely on `niri-session` + journal.
- `spawn-sh` needs `/bin/sh` — present on NixOS.
- Keyboard layout is `se`; keep it unless the user says otherwise (VM console layout is
  separate and may still be `us` until greetd starts, which is normal).
- `focus-follows-mouse max-scroll-amount="0%"` and `warp-mouse-to-focus` behave oddly in
  a VM with a tablet pointer; if the cursor warps constantly, that is a VM input-device
  issue, not a config error. Note it, do not "fix" the config.

Rollback: remove module, rebuild, delete `~/.config/niri` (HM-owned). No login impact.

---

### [ ] P12 — Noctalia (bar/shell)

**Goal:** the shell that draws the bar, launcher, control center, lock screen and handles
volume/brightness, with the migrated `config.toml`.

Source: `roles/noctalia/files/config.toml` (bar radius/margins, keybinds, `font_family =
"Inter"`, `polkit_agent = true`, `theme.source = "community"`, `community_palette = "ADW"`,
wallpaper dir + default `gritty.png`).

New file `modules/desktop/noctalia.nix` + `modules/desktop/files/noctalia/config.toml`:

```nix
{ pkgs, ... }:
{
  flake.nixosModules.desktop-noctalia =
    { ... }:
    {
      environment.systemPackages = [ pkgs.noctalia ];
      home-manager.users.alfrest.xdg.configFile."noctalia/config.toml".text = config;
    };
}
```

with `config` = `readFile` + `replaceStrings` for the wallpaper:

```toml
[wallpaper]
directory = "...nix store dir..."
    [wallpaper.default]
    path = "...nix store path..."
```

Decision needed (D6): pick a `pkgs.nixos-artwork.wallpapers.*` wallpaper with the user
(candidates: `moonscape`, `nineish-catppuccin-mocha`, `simple-dark-gray`). The Arch
wallpaper path `/usr/share/backgrounds/archlinux/gritty.png` does not exist on NixOS.
Working substitution pattern:
```nix
wallpaper = pkgs.nixos-artwork.wallpapers.moonscape.gnomeFilePath;  # verified attr
```

Runtime checks (inside a niri session):
```sh
noctalia --version
noctalia msg panel-toggle launcher      # must open the launcher
noctalia msg volume-up                  # bar volume OSD
noctalia msg session lock               # lock screen
```
Visual: bar with 0 radius and no end margins, Inter font, ADW palette, wallpaper applied,
polkit prompt appears when an app asks for auth.

Gotchas:
- Noctalia in nixpkgs is 5.x (`noctalia`), Quickshell-based (Qt). On llvmpipe the bar may
  be slow; if it is unusable, the escape hatch is `waybar` (the unused source role) — that
  is a new phase, not a hotfix inside P12.
- `polkit_agent = true` in noctalia's own config **and** the niri startup spawn of the KDE
  agent would be two polkit agents. Pick one: the migrated niri config spawns the KDE
  agent (parity with the old machine), so set `polkit_agent = false` **or** drop the niri
  spawn line — decide, document in the commit message, never run both.
- Noctalia's config path must stay `~/.config/noctalia/config.toml` (matches the source).
- If the package needs `python3Packages.psutil` / `pygobject3` at runtime, that is a
  packaging bug to report, not something to patch in `gtk.nix`.

Rollback: remove module; niri keeps working (only the startup spawn and bind targets fail).

---

### [ ] P13 — greetd + tuigreet (full parity login)

**Goal:** boot → tuigreet → login as `alfrest` → niri-session, with gnome-keyring
unlocked at login. This is the highest-risk phase; do it only when P10–P12 are verified
working and you have an SSH session available for recovery.

Source: `roles/tuigreet/tasks/main.yml`, `templates/config.toml.j2`, `templates/greetd`
(PAM), and niri's `gnome-keyring` dependency.

New file `modules/desktop/greetd.nix`:

```nix
{ pkgs, ... }:
{
  flake.nixosModules.desktop-greetd =
    { ... }:
    {
      services.greetd = {
        enable = true;
        useTextGreeter = true;            # tuigreet is a TUI: avoids systemd spam on tty1
        settings = {
          terminal.vt = 1;
          default_session = {
            user = "greeter";
            command = "${pkgs.tuigreet}/bin/tuigreet --remember --remember-session --cmd ${pkgs.niri}/bin/niri-session";
          };
        };
      };

      # The NixOS greetd module already declares security.pam.services.greetd and sets
      # enableGnomeKeyring from services.gnome.gnome-keyring.enable, which P10 turns on.
      # Do NOT copy /etc/pam.d/greetd from the Ansible repo.

      services.displayManager.enable = true;   # set by the module; stated for clarity
    };
}
```

Deliberate differences from the source (document them in the commit):
1. `--cmd ${pkgs.niri}/bin/niri-session` — the source had no `--cmd` and therefore never
   started niri (see §1).
2. No manual `/etc/pam.d/greetd` template; NixOS generates it (`pam_securetty`,
   `system-local-login`, `pam_gnome_keyring auto_start` come from the PAM module).
3. `useTextGreeter = true` because tuigreet is text-based (the old hand-written config
   had no equivalent).

Steps:
1. Record recovery instructions **before** rebuilding:
   - SSH from another terminal (`openssh` is already enabled), or
   - at the boot menu pick the previous generation, or
   - `Ctrl+Alt+F2` → getty (greetd disables `autovt@tty1` only).
2. Rebuild, then reboot (greetd only takes over boot/login).
3. If niri fails, log in on tty2 as `alfrest` and run
   `niri-session` from the shell to see the real error, then
   `sudo systemctl isolate multi-user.target` to get getty back without another reboot.

Runtime checks:
```sh
systemctl status greetd
journalctl -b -u greetd --no-pager | tail -40
loginctl show-session $(loginctl | awk '/alfrest/{print $1; exit}') -p Type   # wayland
# keyring actually unlocked (not just present):
secret-tool search --all xdg:schema org.freedesktop.Secret.Generic | head   # or:
busctl --user list | grep -i secret
```
Visual: tuigreet remembers the last user, typing the password unlocks the keyring (no
"unlock keyring" prompt inside the session), niri starts with the noctalia bar, lock
screen (`Super+Escape`) asks for the password and unlocks.

Gotchas / lockout drills:
- `services.greetd.settings.terminal.vt = 1` conflicts with `boot.kernelParams` console
  settings if anything else claims tty1. Only one display manager.
- If the VM console is a serial console (not a VGA/SPICE display), greetd on tty1 will
  never be visible. Confirm with the user that the console is graphical before this
  phase (D1 says yes, but re-confirm at rebuild time).
- tuigreet's `--remember-session` writes state under `/var/cache/tuigreet`; the NixOS
  module creates that directory. Do not create it yourself.
- If login loops back to tuigreet: `journalctl -b -u greetd` shows the command exit code;
  usual causes are a broken `config.kdl` (run `niri validate` as the user first) or a
  missing `/dev/dri`.
- Do not add `services.xserver.displayManager.*` options; greetd replaces the DM.

Rollback: `git revert` + rebuild, or at boot pick the pre-greetd generation. Both leave
the machine reachable via SSH.

---

### [ ] P14 — Zen browser flake input (+ playerctl wiring) — **do before P11**

**Goal:** make `${pkgs.zen-browser}` exist for P11's `Mod+B` bind.

`flake.nix`:

```nix
inputs.zen-browser = {
  url = "github:0xc000022070/zen-browser-flake";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.home-manager.follows = "home-manager";
};
```

Pass it to the host (`modules/hosts/vm/default.nix` already has `specialArgs`; add
`zen-browser = inputs.zen-browser.packages.${system}.default;` or expose it as
`pkgs-unstable`-style argument).

New file `modules/home/media.nix` (or fold into `modules/home/cli-tools.nix`):

```nix
{ pkgs, zen-browser, ... }:
{
  flake.nixosModules.home-media =
    { ... }:
    {
      home-manager.users.alfrest.home.packages = [ zen-browser pkgs.playerctl ];
    };
}
```

Verified: the flake exposes `packages.<system>.default` (also `beta`, `twilight`,
`twilight-official`, `*-unwrapped`). Pin `default`; do not chase `twilight`.

Runtime checks:
```sh
zen --version
playerctl --version
playerctl status        # no player running is fine
```

Gotchas:
- Third-party input: `nix flake update` will bump it; that is expected and unrelated to
  nixpkgs. If it breaks evaluation, `nix flake lock --update-input zen-browser` to a known
  good rev or drop the bind.
- Add both `follows` lines or you evaluate a second nixpkgs and a second home-manager
  (huge eval, option conflicts).
- Because P11 interpolates the binary path, the package attribute name must be stable:
  `packages.${system}.default`.

Rollback: revert flake.nix + lock (`git checkout flake.lock`), remove module.

---

### [ ] P15 — Parity audit + cleanup

**Goal:** prove nothing in scope was silently dropped and remove transitional duplicates.

Checklist (each line is a check, not a claim):
1. Diff every source config file against its Nix counterpart (appendix A has the source
   paths). Report intentional differences explicitly: emacs bind removed, PAM file
   generated, `--cmd` added, wallpaper swapped, alacritty theme path changed,
   oh-my-zsh/TPM cloning removed, apt/fd shim removed, rbw/vault dropped.
2. `modules/system/packages.nix` no longer duplicates anything now provided per-user
   (`git`, `neovim`, `lazygit`, `herdr` decision, `vim`/`wget` stay system-wide).
3. No secrets anywhere: `git grep -nE "API_KEY|PASSWORD|vault|rbw|SSH_AUTH_SOCK" -- modules/`
   must return only comments that say they were removed.
4. No Arch-isms: `git grep -nE "pacman|/usr/lib|/usr/bin|aur_builder|yay" -- modules/`.
5. Full verification block + a reboot test (login → bar → terminal → lock → unlock).
6. Update `/home/alfrest/nixos-config/AGENTS.md` if the module layout introduced new
   conventions (new `modules/home/` and `modules/desktop/` trees, `files/` subdirs).
7. Merge `feat/desktop-suite` → `main` only after P15 passes.

---

## 6. Progress log (other sessions update this)

| Phase | Status | Commit | Date | Notes / verification evidence |
| --- | --- | --- | --- | --- |
| P0 branch + baseline | done | branch base | `feat/desktop-suite` created; parse, `nix flake check`, `dry-build` all green |
| P1 xdg dirs | todo | | | |
| P2 fonts | todo | | | |
| P3 cli tools | todo | | | |
| P4 git + zsh | todo | | | |
| P5 gtk | todo | | | |
| P6 alacritty | todo | | | |
| P7 tmux | todo | | | |
| P8 herdr | todo | | | |
| P9 nvim | todo | | | |
| P10 graphics | todo | | | |
| P14 zen + playerctl | todo | | | must run before P11 |
| P11 niri | todo | | | |
| P12 noctalia | todo | | | |
| P13 greetd | todo | | | highest risk |
| P15 audit | todo | | | |

**Blockers:** (none yet — add date, symptom, command output, and what was tried)

---

## 7. Risk register

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| greetd misconfiguration locks out the VM | medium | high | SSH stays enabled; P13 last; previous generation in boot menu; tty2 getty still works; verified recovery drill documented in P13 |
| niri cannot create a GL context in QEMU (no virgl) | medium | high | P10 checks `/dev/dri` first; if missing, stop and fix the VM's display device on the host; last resort software rendering via `LIBGL_ALWAYS_SOFTWARE` |
| Noctalia (Quickshell/Qt) unusable on llvmpipe | medium | medium | Keep greetd phase separate; fallback is `waybar` (source role exists, unused) as a new phase |
| HM-managed nvim config is read-only, LazyVim cannot write lockfile/extras | high if unaddressed | low | P9 patches `lazy.lua` lockfile path (recommended) or uses `mkOutOfStoreSymlink` |
| Third-party zen-browser flake breaks on update | low | low | Pin in `flake.lock`; keep bind isolated in `media.nix` |
| Two polkit agents (noctalia + KDE) | medium | low | P12 explicitly picks one |
| Loss of `lazy-lock.json` pins during copy | low | medium | P9 diff/count check before commit |
| Secrets accidentally copied from a template | low | high | P15 `git grep` gate; vault/rbw explicitly out of scope |
| Scope creep into server roles | medium | medium | §1 skip list; if a session is tempted, stop and ask |
| `nix flake update` during migration changes package names | low | low | Don't run it mid-phase; update as its own commit |

---

## 8. Reference: values that must be preserved

Quick reference so a session does not have to re-clone the source repo. Source paths are
relative to `https://github.com/alfrest/ansible-dotfiles` (`d75c36b`).

### Fonts
- Alacritty: `JetBrains Mono Nerd Font Mono` Regular/Bold/Italic, size `12`.
- Waybar (if ever used): `JetBrainsMono Nerd Font Propo`, 13px.
- Noctalia shell: `Inter`.
- Installed families: Inter, Source Serif, JetBrains Mono Nerd Font, FiraCode Nerd Font.

### GTK / theme
- `gtk-theme = adw-gtk3-dark`, `color-scheme = prefer-dark`.
- Alacritty theme: `vscode.toml` from `alacritty/alacritty-theme`.
- herdr: Dark+ palette, `prefix = "alt+space"`, `ui.accent = "#4DA6FF"`.
- tmux: Dark+ palette block, `#D4D4D4` / `#007ACC` / `#3794FF` / `#1E1E1E`.

### niri
- `xkb layout "se"`, `numlock`, `click-method "clickfinger"`, `natural-scroll`,
  mouse `accel-speed -0.6`, `warp-mouse-to-focus`, `focus-follows-mouse max-scroll-amount="0%"`.
- `layout.gaps 1`, preset widths 1/3, 1/2, 2/3, default column width 1/2.
- focus-ring off, border width 1, active `#6a9fb5`, inactive `#505050`.
- `prefer-no-csd`, `hotkey-overlay.skip-at-startup`, hot corners off.
- screenshot path `~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png`.
- binds: see appendix A (full KDL), minus `Mod+E`.

### zsh
- theme `robbyrussell`; plugins `vi-mode`, `git`, `fzf`, `zsh-syntax-highlighting`,
  `zsh-autosuggestions`; `VI_MODE_SET_CURSOR` / `VI_MODE_RESET_PROMPT_ON_MODE_CHANGE` true;
  `DISABLE_UPDATE_PROMPT`; `EDITOR` = `vim` over SSH else `nvim`; `alias tm='tmux attach || tmux'`;
  `eval "$(zoxide init zsh)"`; `QT_QPA_PLATFORMTHEME=xdgdesktopportal`.

### git
- user `alfrest`, email `21663772+alfrest@users.noreply.github.com`, `init.defaultBranch=main`,
  `pull.rebase=false`.

### noctalia
- bar margins 0, radius 0; keybinds down `Down`/`Ctrl+n`, up `Up`/`Ctrl+p`;
  `font_family = "Inter"`; `theme.source = "community"`, `community_palette = "ADW"`.

### tuigreet
- `--remember --remember-session`; VT 1; user `greeter`; niri as the session command (added).

---

## 9. Appendix A — source files to diff against

Copy these out of a fresh clone (`git clone https://github.com/alfrest/ansible-dotfiles`)
when verifying parity. They are the complete in-scope payload:

```
roles/xdg_user_dirs/tasks/main.yml
roles/fonts/tasks/main.yml
roles/cli_tools/tasks/main.yml
roles/git/files/gitconfig
roles/zsh/files/zshrc
roles/zsh/templates/zshenv.j2          # secrets lines dropped
roles/gtk/tasks/main.yml
roles/alacritty/files/alacritty.toml
roles/tmux/files/tmux.conf
roles/herdr/files/config.toml
roles/nvim/files/nvim/**               # vendored LazyVim tree (includes dotfiles)
roles/niri/templates/config.kdl.j2
roles/noctalia/files/config.toml
roles/tuigreet/templates/config.toml.j2
roles/tuigreet/templates/greetd        # replaced by NixOS PAM module
inventories/local/host_vars/dsk.yml    # niri output vars only
```

The `niri` output values (`DP-2`, `2560x1440@239.958`, scale `1`) belong to the physical
workstation and are **not** migrated to the VM.

---

## 10. Open items for the user

1. P2: confirm FiraCode Nerd Font is still wanted (the Arch branch never downloaded it;
   it was only fetched on Debian/Ubuntu).
2. P9: confirm the lockfile strategy (recommended: lockfile in the state dir).
3. P12: choose the NixOS wallpaper (D6).
4. P12: confirm no JDK is needed for `after/ftplugin/java.lua`.
5. P13: confirm at rebuild time that the VM console is graphical (not serial).
6. Later, outside this plan: if the API keys are wanted back, decide on a secret manager
   (agenix/sops-nix) as a separate migration — do not bolt it onto a phase.
