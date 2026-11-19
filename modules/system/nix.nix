# Nix daemon settings.
#
# `nix-command` and `flakes` are still experimental features; enabling them here
# lets `nix flake check` and `nixos-rebuild --flake .#vm` work without flags.
{ ... }:

{
  flake.nixosModules.nix = {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # `@wheel` may override daemon settings at runtime without sudo.
      trusted-users = [ "@wheel" ];

      # The daemon GCs dead paths during a build before it fails for lack of
      # space. Generations are gc roots, so this never shortens rollback
      # history.
      min-free = 5368709120; # 5 GiB
      max-free = 21474836480; # 20 GiB

      # Hardlink duplicate files as they land in the store.
      auto-optimise-store = true;
    };

    # Age-based pruning is the only thing that drops generations (system and
    # Home Manager alike); the space-based `min-free` above cannot.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
}
