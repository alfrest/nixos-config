# Doom Emacs (`$DOOMDIR`)

This directory is `$DOOMDIR`. `modules/tools/emacs.nix` links it to
`~/.config/doom` with `mkOutOfStoreSymlink`, so edits land here directly. The
Doom core checkout is a separate manual clone at `~/.config/emacs`: nothing
from it belongs in this repo, and no elisp package is installed through Nix
(`emacsPackages`) — Doom installs those from `packages.el`.

## Applying changes

- `config.el` — restart Emacs or `M-x doom/reload`; no sync needed.
- `init.el` (module list) and `packages.el` (`package!` declarations) — run
  `doom sync` before restarting, otherwise modules/packages are not installed
  and autoloads stay stale.
- `custom.el` — `custom-file` points here, so Custom writes it rather than you.
  It also holds the `custom-safe-themes` hashes.

Keep the `;;; $DOOMDIR/...` headers and the `lexical-binding` cookie.

## What Nix provides

`modules/tools/emacs.nix` supplies the `emacs` binary, aspell plus its
dictionary, `nerd-fonts.symbols-only`, the user daemon unit (gated on
`~/.config/emacs/early-init.el` existing) and `EMACS_SOCKET_NAME`. Stylix
provides the patched JetBrains Mono and the palette. The theme in `config.el`
(`kanagawa-dragon`) is chosen to match that palette and its hash is allowlisted
in `custom.el`; change the two together.

## Verify

```sh
doom sync            # after init.el or packages.el changes
doom doctor          # when startup misbehaves
systemctl --user restart emacs
```

The daemon's socket is `~/.config/emacs/server/server`, which is why the Nix
module sets `EMACS_SOCKET_NAME`.
