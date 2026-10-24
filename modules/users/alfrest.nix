# Everything about the `alfrest` user in one place: the NixOS account and its
# Home Manager environment. Both halves describe the same person, so they live
# in the same module instead of being split across a system tree and a home
# tree where they could drift apart.
{ ... }:

{
  flake.nixosModules.user-alfrest =
    { pkgs, ... }:
    {
      users.users.alfrest = {
        isNormalUser = true;
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
        packages = with pkgs; [ ];
      };

      # `home-manager.users` exists because the host selects
      # `nixosModules.home-manager`; feature modules can add to this same tree
      # with `home-manager.users.alfrest.<option> = ...`.
      home-manager.users.alfrest = {
        # Home Manager's counterpart to `system.stateVersion`: the release this
        # home environment was first created on. Like `system.stateVersion`,
        # never change it after the fact.
        home.stateVersion = "26.11";

        # Per-user packages belong here rather than in
        # `users.users.alfrest.packages` or `environment.systemPackages`.
        home.packages = with pkgs; [ ];
      };
    };
}
