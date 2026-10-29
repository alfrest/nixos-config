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
