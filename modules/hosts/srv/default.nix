{ self, inputs, ... }:

let
  system = "x86_64-linux";

  # Unstable nixpkgs; modules see it as `pkgs-unstable`.
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${system};
in

{
  flake.nixosConfigurations.srv = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit pkgs-unstable; };

    modules = [
      # Headless: `base` only, never the `desktop` meta module.
      {
        networking.hostName = "srv";

        # Laptop used as a server: closing the lid must not suspend it.
        services.logind.settings.Login = {
          HandleLidSwitch = "ignore";
          HandleLidSwitchExternalPower = "ignore";
          HandleLidSwitchDocked = "ignore";
        };

        services.immich.mediaLocation = "/mnt/btrfs-pool/@appdata/immich/library";

        # The pool is mounted with `nofail`; do not start against the root
        # filesystem if it failed to mount.
        systemd.services.immich-server.unitConfig.ConditionPathIsMountPoint = "/mnt/btrfs-pool";
      }

      self.nixosModules.srv-hardware
      self.nixosModules.boot

      self.nixosModules.base
      self.nixosModules.immich
    ];
  };
}
