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

      # Keep some store paths free so recent generations stay rollback-able.
      min-free = 5368709120; # 5 GiB
      max-free = 21474836480; # 20 GiB
    };
  };
}
