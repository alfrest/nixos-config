{ ... }:

{
  flake.nixosModules.packages =
    { pkgs, pkgs-unstable, ... }:
    {
      environment.systemPackages = with pkgs; [
        # Keep system-wide so they exist even with a broken Home Manager
        # generation (recovery shells, root logins). User tools live in
        # modules/home/.
        vim
        wget

        # Fast-moving tools from the unstable channel. `herdr` stays here
        # because Home Manager modules only see stable `pkgs`.
        pkgs-unstable.opencode
        pkgs-unstable.herdr
      ];
    };
}
