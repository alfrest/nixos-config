# First NixOS version installed here. Never change it after the initial install.
{ ... }:

{
  flake.nixosModules.state-version = {
    system.stateVersion = "26.05";
  };
}
