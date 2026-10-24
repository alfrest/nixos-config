# Enable the OpenSSH daemon.
{ ... }:

{
  flake.nixosModules.openssh = {
    services.openssh.enable = true;
  };
}
