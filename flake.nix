{
  description = "NixOS VM configuration using the dendritic pattern with flake-parts";

  inputs = {
    # Stable release channel. Everything comes from here unless a package is
    # listed as an exception (see `nixpkgs-unstable` below). Change the number
    # here when moving to the next stable release: https://nixos.org/download
    # Use `nix flake update` to update the flake to the latest revision of the
    # chosen release channel.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Unstable release channel, used only for a handful of fast-moving
    # packages that are either missing or far behind in stable. It is a second,
    # independent nixpkgs instance; modules receive it as the `pkgs-unstable`
    # argument (see modules/system/packages.nix).
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";

    # Home Manager, integrated as a NixOS module (see modules/system/home-manager.nix).
    # Must track the same release as `nixpkgs` above, otherwise Home Manager
    # options and the NixOS release can disagree.
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      # Every .nix file under ./modules is itself a flake-parts module.
      inputs.import-tree ./modules
    );
}
