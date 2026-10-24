# List packages installed in system profile.
# You can use https://search.nixos.org/ to find more packages (and options).
{ ... }:

{
  flake.nixosModules.packages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        vim # Do not forget to add an editor to edit the configuration! The Nano editor is also installed by default.
        wget
        opencode
        herdr
      ];
    };
}
