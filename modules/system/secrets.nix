# Secret management (sops-nix). This file contains no secret material: the
# encrypted files live in `./secrets` at the repo root, are committed as
# ciphertext, and are decrypted into `/run/secrets` at activation *on the host*,
# with that host's own SSH host key.
#
# Which secrets a host can read is decided by `.sops.yaml`: a host decrypts a
# file only if its recipient is listed for that file. Two kinds of file exist:
# `secrets/common.yaml` (every host) and `secrets/<host>.yaml` (that host only).
# Referencing a secret from a file the host is not a recipient of fails the
# activation, so the recipient list is enforced rather than advisory.
#
# Declare secrets in the modules that use them, always naming the file, so the
# recipient set is visible where the secret is referenced:
#
#   sops.secrets.smb-credentials = {
#     sopsFile = ../../secrets/srv.yaml;
#     key = "smb-credentials";
#     owner = "root";
#     mode = "0400";
#   };
#
# `sops.defaultSopsFile` is deliberately unset: a secret without an explicit
# `sopsFile` fails evaluation instead of silently landing in the wrong file.
#
# Runbook — adding a host, editing, rotating, srv/SMB example: docs/secrets.md
{ inputs, ... }:

{
  flake.nixosModules.secrets =
    { ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      # The machine identity is the ed25519 SSH host key that OpenSSH already
      # generates, so nothing extra has to be provisioned. sops-nix converts it
      # to an age identity at activation; the matching recipient in `.sops.yaml`
      # is `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`.
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
}
