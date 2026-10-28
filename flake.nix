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

    # Secret management. Encrypted files live in `./secrets`; each host decrypts
    # them at activation with its own SSH host key. Nothing secret is ever in the
    # store or in git. Layout and runbook: docs/secrets.md.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # GTK/Qt theming, fonts, icons and cursor from one base16 palette. The
    # release branch must match nixpkgs and home-manager (Stylix warns
    # otherwise); the enabled targets are listed in modules/desktop/stylix.nix.
    stylix = {
      url = "github:nix-community/stylix/release-26.05";
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
      inputs.import-tree ./modules
    );
}
