# Home Manager integrated as a NixOS module, so `home-manager.users.*` is built
# and activated by `nixos-rebuild` in the same generation as the system.
#
# User-specific settings belong under `home-manager.users.<name>`;
# `environment.systemPackages` is for things that must exist system-wide
# (services, sudo, recovery shells).
{ inputs, ... }:

{
  flake.nixosModules.home-manager =
    { ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      # Reuse the system's nixpkgs instead of evaluating a second instance.
      home-manager.useGlobalPkgs = true;

      # Install packages through the system generation so they roll back with
      # `nixos-rebuild` instead of a separate per-user profile.
      home-manager.useUserPackages = true;

      # Move conflicting files aside instead of aborting activation.
      home-manager.backupFileExtension = "hm-backup";
    };
}
