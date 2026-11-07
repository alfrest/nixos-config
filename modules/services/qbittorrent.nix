{
  flake.nixosModules.qbittorrent =
    { pkgs, ... }:
    {
      services.qbittorrent = {
        enable = true;

        # Same user as webdav serves with, so downloads need no extra
        # group/umask juggling to manage over samba/webdav.
        user = "alfrest";
        group = "users";

        webuiPort = 8080;
        torrentingPort = 6881;
        extraArgs = [ "--confirm-legal-notice" ];
      };

      # The stock `openFirewall` would also open the WebUI port, which is
      # pointless behind Caddy (it proxies localhost); peers need both
      # TCP and UDP on the torrenting port (uTP rides on the UDP socket).
      networking.firewall = {
        allowedTCPPorts = [ 6881 ];
        allowedUDPPorts = [ 6881 ];
      };

      systemd.services.qbittorrent = {
        # nofail mounts; never start against the root filesystem.
        after = [ "srv-shared-servarr.mount" ];
        # The @servarr subvolume is only mounted at /srv/shared/servarr,
        # not visible as a mount point under the pool top level.
        unitConfig.ConditionPathIsMountPoint = "/srv/shared/servarr";
        serviceConfig.ExecStartPre = pkgs.writeShellScript "qbittorrent-downloads-dir" ''
          ${pkgs.coreutils}/bin/mkdir -p /mnt/btrfs-pool/@servarr/qbittorrent
        '';
      };
    };
}
