{ ... }:

{
  flake.nixosModules.avahi = {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Chromecast SSDP replies land on the ephemeral source port of the discovery
    # request, which the firewall would otherwise drop.
    networking.firewall.allowedUDPPortRanges = [
      {
        from = 32768;
        to = 60999;
      }
    ];
  };
}
