{ ... }:

{
  flake.nixosModules.user-alfrest =
    { pkgs, ... }:
    {
      users.users.alfrest = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        packages = with pkgs; [ ];
      };

      home-manager.users.alfrest = {
        # Never change after the initial install; must match `system.stateVersion`.
        home.stateVersion = "26.05";

        # Per-user packages belong here, not in `users.users.alfrest.packages`
        # or `environment.systemPackages`.
        home.packages = with pkgs; [ ];
      };
    };
}
