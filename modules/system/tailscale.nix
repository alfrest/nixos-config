# Tailscale (WireGuard mesh VPN). Shared by every host via `system-common`.
#
# Enabling the service only brings up the daemon; the node still has to join the
# tailnet once with `sudo tailscale up`. Login state persists in
# `/var/lib/tailscale`, so it survives reboots and rebuilds.
#
# `useRoutingFeatures = "client"` sets `checkReversePath = "loose"` (required to
# receive traffic from exit nodes and subnet routers) and trusts the tailscale
# interface in the firewall. It does not advertise this host as a router.
#
# To join non-interactively later, store a reusable auth key in
# `secrets/common.yaml` and add:
#
#   services.tailscale.authKeyFile = config.sops.secrets.tailscale-auth-key.path;
{ ... }:

{
  flake.nixosModules.tailscale = {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };
  };
}
