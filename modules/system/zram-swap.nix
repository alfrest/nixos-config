{ ... }:

{
  flake.nixosModules.zram-swap =
    { ... }:
    {
      zramSwap = {
        enable = true;
        # Half of RAM compressed; on a 4GB box this leaves RAM for the working
        # set while still giving swap headroom for Immich/Open WebUI spikes.
        memoryPercent = 50;
        # Outrank any disk swap on the host.
        priority = 100;
      };
    };
}
