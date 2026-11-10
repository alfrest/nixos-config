# Wireshark GUI. Wireshark itself is a system package so its `dumpcap`
# helper gets the cap_net_raw/cap_net_admin wrapper, letting alfrest
# capture traffic without root.
{ ... }:

{
  flake.nixosModules.wireshark =
    { pkgs, ... }:
    {
      programs.wireshark = {
        enable = true;
        # Upstream module default is `wireshark-cli`; this installs the Qt GUI.
        package = pkgs.wireshark;
      };

      # Capture is gated on the `wireshark` group (the dumpcap wrapper is
      # u+rx,g+x). extraGroups lists merge across modules.
      users.users.alfrest.extraGroups = [ "wireshark" ];
    };
}
