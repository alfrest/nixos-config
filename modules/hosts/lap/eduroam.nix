# Declarative eduroam (Lund University) profile. The CAT installer's profile
# marks the Wi-Fi password agent-owned (`password-flags = 1`), so NM discards it
# on logout/suspend and autoconnect then fails. Here the password comes from a
# sops secret instead: `ensureProfiles` renders the profile through envsubst
# with `environmentFiles`, so `$EDUROAM_*` below are expanded from the decrypted
# env file (`EDUROAM_IDENTITY=...`, `EDUROAM_PASSWORD=...`) and never hit the
# repo or the store in plaintext.
#
# The CA cert is extracted from the CAT-generated installer at build time.
# fetchurl pins the exact bytes, so if Lund rotates their RADIUS CA or GÉANT
# changes the installer template the rebuild fails loudly instead of silently
# trusting new content; re-pin by re-downloading and `nix hash file`.
{
  flake.nixosModules.eduroam =
    { config, pkgs, ... }:
    let
      cat-installer = pkgs.fetchurl {
        url = "https://cat.eduroam.org/user/API.php?action=downloadInstaller&device=linux&profile=1338";
        sha256 = "FWSqG5T7FBsH85b2w5P6N8c3eIzNQ68TJ6z2X76Cy1k=";
      };

      extract-ca = pkgs.writeText "extract-eduroam-ca.py" ''
        import re
        import sys

        src = open(sys.argv[1]).read()
        ca = re.search(r'Config\.CA = """(.*?)"""', src, re.S).group(1)
        sys.stdout.write(ca)
      '';

      lu-radius-ca = pkgs.runCommand "lu-radius-ca.pem" { } ''
        ${pkgs.python3}/bin/python3 ${extract-ca} ${cat-installer} > $out
      '';
    in
    {
      sops.secrets.eduroam-env = {
        sopsFile = ../../../secrets/lap.yaml;
        key = "eduroam-env";
        mode = "0400";
        restartUnits = [ "NetworkManager-ensure-profiles.service" ];
      };

      networking.networkmanager.ensureProfiles = {
        environmentFiles = [ config.sops.secrets.eduroam-env.path ];

        profiles.eduroam = {
          connection = {
            id = "eduroam";
            type = "wifi";
          };
          wifi = {
            mode = "infrastructure";
            ssid = "eduroam";
          };
          wifi-security = {
            key-mgmt = "wpa-eap";
            proto = "rsn";
            pairwise = "ccmp";
            group = "ccmp";
          };
          "802-1x" = {
            eap = "peap";
            identity = "$EDUROAM_IDENTITY";
            anonymous-identity = "anonymous@lu.se";
            ca-cert = "${lu-radius-ca}";
            domain-match = "radius.lu.se";
            phase2-auth = "mschapv2";
            password = "$EDUROAM_PASSWORD";
          };
          ipv4.method = "auto";
          ipv6.method = "auto";
        };
      };
    };
}
