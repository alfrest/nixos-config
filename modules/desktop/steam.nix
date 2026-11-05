{ ... }:

{
  flake.nixosModules.desktop-steam =
    { ... }:
    {
      nixpkgs.config.allowUnfreePackages = [
        "steam"
        "steam-unwrapped"
      ];

      programs.steam.enable = true;
    };
}
