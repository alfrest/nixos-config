# SMB file server for /srv/data (srv only).
#
# Samba keeps its own NTLM passdb, separate from the unix password. The
# sops-managed `smb-pass` feeds `smbpasswd` at service start: it adds `alfrest`
# to the passdb if missing and (re)sets the password, so rotating the secret in
# secrets/srv.yaml takes effect on the next rebuild. Root runs smbpasswd, so no
# old password is needed.
{ config, lib, pkgs, ... }:

{
  flake.nixosModules.samba =
    { config, pkgs, ... }:
    {
      sops.secrets."smb-pass" = {
        sopsFile = ../../secrets/srv.yaml;
        owner = "root";
        mode = "0400";
      };

      services.samba = {
        enable = true;
        openFirewall = true;
        settings = {
          global = {
            security = "user";
            "server min protocol" = "SMB2";
            "server role" = "standalone server";
          };
          data = {
            path = "/srv/data";
            browseable = "yes";
            "read only" = "no";
            "valid users" = "alfrest";
          };
        };
      };

      # Discovery for Windows; Linux/macOS clients find the server by hostname.
      services.samba-wsdd = {
        enable = true;
        openFirewall = true;
      };

      systemd.services."samba-smbd" = {
        after = [ "sops-nix.service" "srv-data.mount" ];
        unitConfig.ConditionPathIsMountPoint = "/srv/data";
        serviceConfig.LoadCredential =
          "smb-pass:${config.sops.secrets."smb-pass".path}";
        preStart = ''
          pw=$(cat "$CREDENTIALS_DIRECTORY/smb-pass")
          if ${pkgs.samba}/bin/pdbedit -L -u alfrest >/dev/null 2>&1; then
            add=""
          else
            add="-a"
          fi
          printf '%s\n%s\n' "$pw" "$pw" \
            | ${pkgs.samba}/bin/smbpasswd -s $add alfrest >/dev/null
        '';
      };
    };
}
