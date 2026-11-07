{ ... }:

{
  flake.nixosModules.user-alfrest =
    { ... }:
    {
      users.users.alfrest = {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" ];
      };

      home-manager.users.alfrest = {
        # Never change after the initial install; must match `system.stateVersion`.
        home.stateVersion = "26.05";
      };
    };
}
