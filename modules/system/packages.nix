# System-wide packages only: things needed even with a broken Home Manager
# generation (recovery shells, root logins) or for `sudo sops` with the host
# key. Everything user-facing lives in per-user module `home.packages`.
{ ... }:

{
  flake.nixosModules.packages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        vim
        wget

        # Editing secrets. sops works with the host key; ssh-to-age derives a
        # host's recipient (see docs/secrets.md).
        sops
        ssh-to-age
      ];
    };
}
