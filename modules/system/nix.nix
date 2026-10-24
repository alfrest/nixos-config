# Nix daemon settings.
#
# `nix-command` and `flakes` are still gated behind experimental features in
# Nix itself. Enabling them here writes them into `/etc/nix/nix.conf` (see
# `experimental-features`), so `nix flake check`, `nixos-rebuild --flake .#vm`
# and friends work without `--extra-experimental-features …` flags or a local
# `NIX_CONFIG` export.
{ ... }:

{
  flake.nixosModules.nix = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Members of `trusted-users` may override daemon settings (substituters,
      # sandbox, extra features, ...) at runtime without sudo — e.g. adding a
      # cache for a one-off build. Root is trusted by default; `@wheel` covers
      # the admin account, so `nix` behaves the same interactively as under
      # `sudo`.
      trusted-users = [ "@wheel" ];

      # Keep unreferenced store paths for a while so a freshly built
      # generation can still be rolled back to after a garbage collection.
      min-free = 5368709120; # 5 GiB
      max-free = 21474836480; # 20 GiB
    };
  };
}
