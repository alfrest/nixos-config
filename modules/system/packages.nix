# List packages installed in system profile.
# You can use https://search.nixos.org/ to find more packages (and options).
{ ... }:

{
  flake.nixosModules.packages =
    { pkgs, pkgs-unstable, ... }:
    {
      environment.systemPackages = with pkgs; [
        vim # Do not forget to add an editor to edit the configuration! The Nano editor is also installed by default.
        neovim
        git
        lazygit
        wget
        # Fast-moving tools: built from the unstable channel (see flake.nix,
        # input `nixpkgs-unstable`) so they keep up with upstream development.
        pkgs-unstable.opencode
        pkgs-unstable.herdr
      ];
    };
}
