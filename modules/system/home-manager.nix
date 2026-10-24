# Home Manager, integrated as a NixOS module.
#
# Home Manager is not run standalone here: this module imports Home Manager's
# own NixOS module, so `home-manager.users.*` is built and activated by
# `nixos-rebuild` in the same generation as the rest of the system.
#
# Because Home Manager is just another NixOS option tree, a feature module may
# set NixOS options and Home Manager options side by side whenever they serve
# the same concern, e.g.
#
#   { pkgs, ... }:
#   {
#     environment.systemPackages = [ pkgs.ripgrep ];              # system-wide
#     home-manager.users.alfrest.programs.git.enable = true;      # user-level
#   }
#
# The only requirement is that the host selects `nixosModules.home-manager`
# (see modules/hosts/vm/default.nix). Everything user-specific should prefer
# `home-manager.users.<name>`; `environment.systemPackages` stays reserved for
# things that must exist system-wide (services, sudo, recovery shells, ...).
{ inputs, ... }:

{
  flake.nixosModules.home-manager =
    { ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      # Reuse the system's nixpkgs instance instead of evaluating a second one,
      # so NixOS and Home Manager see exactly the same `pkgs` (same overlays,
      # same versions).
      home-manager.useGlobalPkgs = true;

      # Install Home Manager packages through the system generation
      # (`users.users.<name>.packages`) rather than a separate per-user
      # `nix profile`. Everything then rolls back with `nixos-rebuild`.
      home-manager.useUserPackages = true;

      # Home Manager refuses to overwrite files it did not create (e.g. an
      # existing ~/.bashrc). Move them aside instead of aborting activation.
      home-manager.backupFileExtension = "hm-backup";
    };
}
