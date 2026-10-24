# Define a user account. Don't forget to set a password with ‘passwd’.
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
    };
}
