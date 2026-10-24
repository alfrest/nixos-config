{
  description = "NixOS VM configuration using the dendritic pattern with flake-parts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Second nixpkgs used only for fast-moving packages; modules see it as `pkgs-unstable`.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

    # Must track the same release as nixpkgs.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen browser; not in nixpkgs. Both `follows` avoid evaluating a second
    # nixpkgs/home-manager. Only `packages.<system>.default` is used, so keep
    # that attribute name stable (it is the `beta` variant, binary `zen-beta`).
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      # Every .nix file under ./modules is itself a flake-parts module.
      inputs.import-tree ./modules
    );
}
