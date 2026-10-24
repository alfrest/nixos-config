# Configure network connections interactively with nmcli or nmtui.
{ ... }:

{
  flake.nixosModules.networking = {
    networking.networkmanager.enable = true;
  };
}
