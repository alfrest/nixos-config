# AGENTS.md

## What this repo is

Single-host NixOS flake for a QEMU VM (host `vm`), tracked in git. No CI, tests, or linter — Nix evaluation is the check. Uses the dendritic pattern: flake-parts + `import-tree`, where every file under `modules/` is itself a flake-parts module.

- `flake.nix` — minimal entrypoint. `flake-parts.lib.mkFlake` evaluates `import-tree ./modules`; outputs are `flake.nixosConfigurations.vm` and the `flake.nixosModules.*` set. nixpkgs pinned to `nixos-unstable` in `flake.lock`.
- `modules/` — auto-imported recursively by `import-tree`. Each file declares exactly one `flake.nixosModules.<name>` feature module (NixOS module inside the flake-parts module); **do not `import` one module from another**, declare it instead. Files/dirs starting with `_` are ignored by `import-tree`.
  - `modules/hosts/vm/default.nix` — defines `flake.nixosConfigurations.vm` by selecting which `self.nixosModules.*` make up the host, and pins the host identity (`networking.hostName = "vm"`). Add a new module to this list to activate it.
  - `modules/hosts/vm/hardware-configuration.nix` — generated machine description from `nixos-generate-config`, wrapped as `nixosModules.vm-hardware`; **never edit the generated settings** (btrfs subvolumes, `qemu-guest.nix`).
  - `modules/system/` — boot, nix daemon settings (`nix-command`/flakes), networking, OpenSSH, packages (`vim`/`wget`/`opencode`/`herdr`), `state-version`.
  - `modules/users/alfrest.nix` — user `alfrest` (`wheel`).
- `/etc/nixos` is a root-owned copy of the old pre-dendritic layout. Edits here are not live until rebuilt from this directory.

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
2. Flake evaluation: `nix flake check` (evaluates `nixosConfigurations.vm`, no build)
3. Build without activating: `nixos-rebuild dry-build --flake .#vm`
4. Package exists in the locked nixpkgs: `nix eval --raw .#nixosConfigurations.vm.pkgs.<name>.name`

Formatting: `nixfmt`/`alejandra` are not installed, and the stock files are not nixfmt-clean. Only if you intentionally format, use `nix shell nixpkgs#nixfmt-rfc-style -c nixfmt -w configuration.nix`; do not reformat `hardware-configuration.nix`.

## Commands

- Apply now: `sudo nixos-rebuild switch --flake .#vm`
- Stage for next boot: `sudo nixos-rebuild boot --flake .#vm`
- Update nixpkgs: `nix flake update`
- Inspect inputs: `nix flake metadata`

Without `--flake`, `nixos-rebuild` targets `/etc/nixos`, not this repo. `sudo` needs a password here (`sudo -n` fails), so ask the user to run privileged rebuilds.

## Constraints

- Never change `system.stateVersion` (`"26.05"`), even after upgrades.
- Always select the `.#vm` flake attribute.
- Flakes read git-tracked files only: `git add` new files before `nix flake check` or `nixos-rebuild`, or they will be invisible.
