# Meta module: the baseline every host imports. Adding a feature here makes it
# part of every host, headless ones included.
{ self, ... }:

{
  flake.nixosModules.base =
    { ... }:
    {
      imports = [
        self.nixosModules.system-common
        self.nixosModules.home-common
      ];
    };
}
