{
  description = "NixOS VM configuration using the dendritic pattern with flake-parts";

  inputs = {
    # This is pointing to an unstable release.
    # If you prefer a stable release instead, you can change the word unstable to the latest number shown here: https://nixos.org/download
    # i.e. nixos-24.11
    # Use `nix flake update` to update the flake to the latest revision of the chosen release channel.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      # Every .nix file under ./modules is itself a flake-parts module.
      inputs.import-tree ./modules
    );
}
