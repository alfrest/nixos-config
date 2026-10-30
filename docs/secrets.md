# Secrets — sops-nix setup

Status: **srv added** (2026-10-29): `secrets/srv.yaml` holds `smb-pass` and
`webdav-pass`, encrypted to srv only; `opencode-api-key` (Open WebUI) still has
to be added there on srv, see `modules/system/open-webui.nix`.
Scope: every host built from this flake (`vm`, `dsk`, `srv`)
Pending: `sops updatekeys secrets/common.yaml` — the shared file is encrypted
to vm + dsk still; run it on either (srv activation does not need it yet).

The repository is public, so the rule is simple: **ciphertext in git, key material
on the host, plaintext only at runtime.** Nothing decrypted ever reaches
`/nix/store`, and no private key is ever committed.

---

## 1. Model

- Each host's **ed25519 SSH host key** is its machine identity. OpenSSH generates
  it at install, so there is nothing extra to provision.
  `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub` prints the public recipient.
- `.sops.yaml` (repo root) maps file paths to recipients. sops encrypts a file to
  the union of recipients on the matching rule, so the rules **are** the access
  control:
  - `secrets/common.yaml` — every host that is listed on that rule
  - `secrets/<host>.yaml` — that host only
- `modules/system/secrets.nix` enables sops-nix and points it at the host key.
  It is part of `modules/meta/system-common.nix`, so every host gets it.
- Decryption happens during `nixos-rebuild` activation, into `/run/secrets/<name>`
  (tmpfs). `nix flake check` and `nixos-rebuild dry-build` never need a key.
- If a host's configuration references a secret from a file it is not a recipient
  of, **activation fails** and the previous generation stays active.

There is no `sops.defaultSopsFile` on purpose: every secret names its `sopsFile`
explicitly, so the recipient set is visible at the declaration site.

## 2. Repository layout

```
.sops.yaml                      # recipients (public keys) + per-file rules
secrets/common.yaml             # encrypted; shared by all hosts
secrets/vm.yaml                 # encrypted; vm only
secrets/srv.yaml                # encrypted; srv only (created when srv exists)
modules/system/secrets.nix      # sops-nix wiring, no secret material
```

`sops` and `ssh-to-age` are in `environment.systemPackages` (`modules/system/packages.nix`),
so the commands below work as root without a Home Manager generation.

## 3. Editing a secret

Editing has to happen on a host that is a recipient, using that host's own key.
No extra key file is needed — the identity is derived inline:

```sh
cd /home/alfrest/nixos-config
sudo sh -c 'SOPS_AGE_KEY=$(ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key) \
  sops secrets/common.yaml'
```

Read-only inspection:

```sh
sudo sh -c 'SOPS_AGE_KEY=$(ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key) \
  sops decrypt secrets/common.yaml'
```

The editor is `$EDITOR` (falls back to `vi`). YAML values must be strings;
multi-line values (an SMB credentials file, a private key) use a block scalar:

```yaml
smb-credentials: |
  username=svc_backup
  password=...
```

Then commit the **ciphertext** and rebuild. Diff review works normally: sops shows
only the changed values as ciphertext.

### Optional: edit from a workstation instead of a host

Uncomment `&alfrest` in `.sops.yaml`, add it to the rules you want, and derive a
local age identity once:

```sh
mkdir -p ~/.config/sops/age
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

This only works if that SSH key has **no passphrase** (`ssh-to-age` cannot unlock
one) — otherwise generate a dedicated key with `age-keygen -o ~/.config/sops/age/keys.txt`
and use its public half as the recipient. Either way the private key stays out of
the repo. Trade-off: you are then part of every recipient set you add it to.

## 4. Using a secret

```nix
sops.secrets.smb-credentials = {
  sopsFile = ../../secrets/srv.yaml;   # which file ⇒ which recipients
  key = "smb-credentials";             # key inside the YAML; default = attribute name
  owner = "root";
  mode = "0400";
};
```

Useful options: `path` (symlink into a fixed location a program expects),
`restartUnits`/`reloadUnits` (restart on change), `neededForUsers` (decrypt before
user creation — required for `users.users.<n>.hashedPasswordFile`, and the secret
must then hold a hash from `mkpasswd`, not a password).

Home Manager secrets are a separate mechanism (`inputs.sops-nix.homeManagerModules.sops`)
and cannot read `/etc/ssh` host keys. Prefer a system secret with
`owner = "alfrest"`; only add the Home Manager module if you deliberately want a
user-owned key.

## 5. Adding a host

Example: `srv`, which needs an SMB password and possibly other machine-local
credentials.

1. Install/ssh into `srv`, then derive its recipient — from another machine:
   ```sh
   ssh-keyscan -t ed25519 srv | ssh-to-age      # or on srv: cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
   ```
2. Add the anchor to `.sops.yaml` and uncomment/extend the rules:
   ```yaml
   keys:
     - &srv age1...
   creation_rules:
     - path_regex: secrets/common\.yaml$
       age:
         - *vm
         - *srv            # <- shared file, add every host
     - path_regex: secrets/srv\.yaml$
       age:
         - *srv            # <- machine-only file
   ```
3. Re-wrap the existing shared file for the new recipient:
   ```sh
   sops updatekeys secrets/common.yaml
   ```
   Do this **before** the first `srv` rebuild, or activation there fails.
4. Create the machine-only file on any host that can already read it — for a
   brand-new host key nobody can, so either create it on `srv` itself once its
   host key exists, or temporarily add `&vm` (and `&alfrest`) to the `srv` rule,
   create the file, then remove the extra recipient with
   `sops rotate -i secrets/srv.yaml`.
5. Declare the secret where it is consumed (for a CIFS/SMB mount):
   ```nix
   sops.secrets.smb-credentials = {
     sopsFile = ../../secrets/srv.yaml;
     key = "smb-credentials";
     mode = "0400";
   };

   fileSystems."/mnt/share" = {
     device = "//nas/share";
     fsType = "cifs";
     options = [ "credentials=${config.sops.secrets.smb-credentials.path}" ];
   };
   ```

The same steps apply to `dsk`: uncomment its anchor, add it to the `common` rule,
run `sops updatekeys secrets/common.yaml`.

## 6. Rotation and removal

| Situation | Command |
| --- | --- |
| Added a recipient to a rule | `sops updatekeys secrets/<file>.yaml` |
| Removed a recipient from a rule | `sops rotate -i secrets/<file>.yaml` |
| A secret leaked (e.g. value pasted in a commit) | change the value, then `sops rotate -i secrets/<file>.yaml`, then rebuild every affected host |
| Host reinstalled → new host key | replace its anchor, then `updatekeys` (and `rotate -i` if the old disk is gone or untrusted) |

`sops updatekeys` alone does **not** invalidate an old copy: the data key stays
the same, so anyone holding the previous ciphertext can still decrypt it. Rotate
when a recipient must lose access.

Practical consequences of keying on host keys:

- **Back up each host's private host key** (`/etc/ssh/ssh_host_ed25519_key`)
  outside the repo. Without it, that host cannot decrypt its files and every
  file must be re-encrypted for a new key.
- A **disk image or VM snapshot** of a host is a copy of its decryption key —
  treat it as one.
- Root on a host can read every secret that host is a recipient of. This guards
  against the public Git history and other machines, not against a compromised
  host.

## 7. Limits worth remembering

- **Per-file granularity.** Every key inside one sops file is readable by every
  recipient of that file. Use separate files when the audience differs.
- **ed25519 only.** The age conversion works for ed25519 host keys (the NixOS
  default). A `services.openssh.hostKeys` entry that replaces the ed25519 key
  must be reflected in `.sops.yaml`.
- **No secrets at evaluation time.** Values are unavailable while Nix evaluates,
  so they cannot be interpolated into store paths, hashes, or `builtins.readFile`.
  That is the point — but it rules out, e.g., deriving a password hash at build
  time.
- **`.sops.yaml` is a CLI convenience.** sops-nix only reads the recipients baked
  into each file; keep the two in sync.
- **Never** put plaintext in `secrets/`, `.gitignore` a plaintext copy, use
  git-crypt, or commit a private key. A dirty-tree evaluation can copy untracked
  files into the store, so `.gitignore` is not a boundary.

## 8. Verification

After any change:

```sh
cd /home/alfrest/nixos-config
find . -name '*.nix' -not -path './.git/*' -exec nix-instantiate --parse {} + >/dev/null
nix flake check
nixos-rebuild dry-build --flake .#vm
```

These run without any key. Decryption is proven only by an activation:

```sh
sudo nixos-rebuild switch --flake .#vm
sudo ls -l /run/secrets/          # only the secrets this host is a recipient of
```
