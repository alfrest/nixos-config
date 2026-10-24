# This option defines the first version of NixOS you have installed on this
# particular machine, and is used to maintain compatibility with application
# data (e.g. databases) created on older NixOS versions.
#
# Most users should NEVER change this value after the initial install, for any
# reason, even if you've upgraded your system to a new NixOS release.
#
# Do NOT change this value unless you have manually inspected all the changes
# it would make to your configuration, and migrated your data accordingly.
{ ... }:

{
  flake.nixosModules.state-version = {
    system.stateVersion = "26.05"; # Did you read the comment?
  };
}
