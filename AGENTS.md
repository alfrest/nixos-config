# AGENTS.md

## What this repo is

NixOS flake managing several machines from one tree — currently four hosts: `srv` (headless server on a repurposed laptop), `vm` (QEMU virtual machine), `dsk` (desktop workstation) and `lap` (daily laptop), with more expected. Shared behaviour lives in common modules under `modules/`; each host selects what it needs. Tracked in git. No CI, tests, or linter — Nix evaluation is the check. Uses the dendritic pattern: flake-parts + `import-tree`, where every file under `modules/` is itself a flake-parts module.

- `flake.nix` — minimal entrypoint. `flake-parts.lib.mkFlake` evaluates `import-tree ./modules`; outputs are one `flake.nixosConfigurations.<host>` per directory under `modules/hosts/` and the `flake.nixosModules.*` set. `nixpkgs` is pinned to `nixos-26.05`; `nixpkgs-unstable` is a second input for fast-moving tools. Both flow into the host evals as the `pkgs-unstable` specialArg, and `pkgs-unstable` alone is forwarded into Home Manager via `home-manager.extraSpecialArgs` (`modules/system/home-manager.nix`) because NixOS `specialArgs` do not reach `home-manager.users.*` submodules. `zen-browser` is a third input, passed down as the `zen-browser` argument. `stylix` (release branch matching the nixpkgs/Home Manager releases) provides the GTK/Qt palette; only its GTK and Qt targets are enabled.
- `modules/` — auto-imported recursively by `import-tree`. Each file declares exactly one `flake.nixosModules.<name>` feature module (NixOS module inside the flake-parts module); **do not `import` one module from another**, declare it instead. A feature module is one feature, whatever level it touches: it may set NixOS options, `home-manager.users.alfrest.*`, or both in the same file (e.g. `tools/zsh.nix`). Files/dirs starting with `_` are ignored by `import-tree`.
  - `modules/hosts/<name>/` — one directory per host, each defining exactly one `flake.nixosConfigurations.<name>`. `default.nix` selects the `self.nixosModules.*` that make up the host and pins its identity (`networking.hostName`, display settings); `hardware-configuration.nix` is the generated machine description from `nixos-generate-config`, wrapped as `nixosModules.<name>-hardware` — **never edit the generated settings** (btrfs subvolumes, `qemu-guest.nix`). Extra host-specific modules may live in the same directory (e.g. `srv/btrfs-scrub.nix`). Adding a host means adding a directory in this shape and `git add`ing it.
    - `srv` — headless server (laptop with the lid closed: lid switch ignored). Imports `base` only, never `desktop`. Runs the service stack (`immich`, `open-webui`, `samba`, `webdav`) plus `zram-swap` and `btrfs-scrub` against the btrfs pool at `/mnt/btrfs-pool` (mounted `nofail`; immich is guarded on the mount).
    - `vm` — QEMU VM: `base` + `desktop`; niri output pinned to `Virtual-1` at 1920x1200@59.885.
    - `dsk` — workstation: `vm`'s set plus the NVIDIA driver (`desktop-nvidia`) and `desktop-openrgb`; `DP-2` at 2560x1440@239.958, scale 1, and a slower pointer than the shared default.
    - `lap` — daily laptop: `vm`'s set plus `keyd`, `bluetooth`, `eduroam`, `lang-java`, `lang-scala`, `steam` and `games`.
  - `modules/system/` — core OS/wiring `system`-level features: boot, nix daemon settings (`nix-command`/flakes), networking, `locale` (`Europe/Stockholm` plus the `sv-latin1` console keymap for the TTY), OpenSSH, `tailscale`, `secrets` (sops-nix wiring, no secret material), `packages` (only `vim`/`wget`/`sops`/`ssh-to-age`; everything user-facing belongs in `home.packages` of a feature module), `zram-swap` (opt-in, `srv`), `state-version` and Home Manager integration (with the `pkgs-unstable` forwarding).
  - `modules/services/` — server applications (`immich`, `open-webui`, `samba`, `webdav`); regular feature modules that only `srv` imports today.
  - `modules/users/alfrest.nix` — user `alfrest` (`wheel`) and its Home Manager base (`home.stateVersion`).
  - `modules/tools/` — per-user feature modules that work without a graphical session (xdg dirs, cli tools incl. `opencode`, git, zsh, `herdr` (package + config), nvim). Fonts are not here: Stylix installs them (`modules/desktop/stylix.nix`).
  - `modules/lang/` — language toolchains for the user (`openjdk25`, `scala`/`metals`/`coursier` from `pkgs-unstable`); `home.packages`, opt-in per host.
  - `modules/desktop/` — everything that needs a graphical session: system-level pieces (`graphics.nix` — Mesa, keyring, polkit, portals; `stylix.nix` — colour scheme, fonts, icons and cursor from the Kanagawa Dragon base16 scheme in `pkgs.base16-schemes`, `autoEnable = false` so only the targets listed there — GTK, Qt, fontconfig, font packages — are themed; `niri.nix` — compositor with the `desktop.niri.output` option and generated KDL; `noctalia.nix` — bar/shell; `greetd.nix` — login → `niri-session`; `nvidia.nix` — proprietary driver; `steam.nix` — client plus 32-bit graphics stack and controller udev rules; `openrgb.nix` — RGB control; `nix-ld-gui.nix`) and per-user modules (`alacritty`, `apps` — media/zen incl. `zen-browser`, `clipboard`, `games`). `games`, `openrgb`, `nvidia` and `steam` are opt-in and not part of the `desktop` meta module; `openrgb`/`nvidia` are only on `dsk`, `steam` and `games` are on `dsk`/`lap` respectively.
  - `modules/meta/` — meta modules that only `imports` other `self.nixosModules.*` entries: `base` (system core + per-user non-GUI defaults) and `desktop` (system desktop stack + per-user GUI modules). Hosts import `base`, and GUI hosts additionally `desktop`; add a feature to the relevant meta module to give it to every host in that class.
  - `modules/files/` — vendored config data (no `.nix` files, so `import-tree` ignores it): `herdr`, `nvim`, `niri`, `noctalia`. Two wiring conventions: files that must stay editable are linked with `lib.file.mkOutOfStoreSymlink` to this live checkout (`herdr`, `nvim`; assumes the repo stays at `/home/alfrest/nixos-config`), while files whose content Nix must rewrite for store paths use `text =` with `builtins.readFile` + `replaceStrings` (`niri`, `noctalia`, resolved from `modules/desktop/` as `../files/...`).
- `secrets/` + `.sops.yaml` — sops-nix ciphertext and its recipients (public keys). `secrets/common.yaml` is shared by every host, `secrets/<host>.yaml` is decryptable by that host's own ed25519 SSH host key only. `modules/system/secrets.nix` is the wiring (part of `base`); it holds no secret material. Never commit plaintext or a private key; runbook in `docs/secrets.md`.
- On machines upgraded from the old pre-dendritic layout, `/etc/nixos` is a root-owned copy. Edits in this repo are only live after a rebuild from this directory.

## Verification is mandatory

`nix-command` and `flakes` are enabled system-wide by `modules/system/nix.nix`
(`nix.settings.experimental-features`), so flake commands work without extra
flags. On a machine still running an older generation (before that module was
activated), prefix commands with:

```sh
export NIX_CONFIG='experimental-features = nix-command flakes'
```

After any change, run these and never report success on a non-zero exit:

1. Syntax: `find . -name '*.nix' -not -path './.git/*' -exec nix-instantiate --parse {} + >/dev/null` (works without the flag)
2. Flake evaluation: `nix flake check` (evaluates every `nixosConfigurations.<host>`, no build)
3. Build without activating: `nixos-rebuild dry-build --flake .#<host>` (the host(s) you touched)
4. Package exists in the locked nixpkgs: `nix eval --raw .#nixosConfigurations.<host>.pkgs.<name>.name`

Formatting: `nixfmt`/`alejandra` are not installed, and the stock files are not nixfmt-clean. Only if you intentionally format, use `nix shell nixpkgs#nixfmt-rfc-style -c nixfmt -w configuration.nix`; do not reformat `hardware-configuration.nix`.

## Commands

- Apply now: `sudo nixos-rebuild switch --flake .#<host>`
- Stage for next boot: `sudo nixos-rebuild boot --flake .#<host>`
- Update nixpkgs: `nix flake update`
- Inspect inputs: `nix flake metadata`

`<host>` must match the machine you are on (`hostname`); this checkout is used on every host. Without `--flake`, `nixos-rebuild` targets `/etc/nixos`, not this repo. `sudo` needs a password here (`sudo -n` fails), so ask the user to run privileged rebuilds.

## Comments

Do not litter the config with comments. The bar is whether the comment helps
someone (human or AI) who reads the file later with no memory of this change:
explain intent, non-obvious choices, workarounds, or upstream quirks. Anything
that just restates the code, narrates the edit, or would be obvious from the
attribute name does not get written. When in doubt, leave it out.

## Constraints

- Never change `system.stateVersion` (`"26.05"`), even after upgrades.
- Always pass an explicit `--flake .#<host>` matching the machine you are on; there is no default host attribute.
- Flakes read git-tracked files only: `git add` new files before `nix flake check` or `nixos-rebuild`, or they will be invisible.
