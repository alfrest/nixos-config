# List packages installed in system profile.
# You can use https://search.nixos.org/ to find more packages (and options).
{ ... }:

{
  flake.nixosModules.packages =
    { pkgs, pkgs-unstable, ... }:
    {
      environment.systemPackages = with pkgs; [
        vim # Do not forget to add an editor to edit the configuration! The Nano editor is also installed by default.
        wget
        # `vim` and `wget` stay system-wide on purpose: they must exist even
        # when the user's Home Manager generation is broken (recovery shells,
        # root logins). Everything else moved to the per-user profile:
        # `git` (modules/home/git.nix), the cli tool set (cli-tools.nix),
        # `neovim` + `lazygit` (nvim.nix).
        #
        # Fast-moving tools: built from the unstable channel (see flake.nix,
        # input `nixpkgs-unstable`) so they keep up with upstream development.
        # `herdr` stays here rather than in modules/home/herdr.nix: Home Manager
        # modules only see stable `pkgs`, so a second copy there would either
        # come from stable (a different store path) or need `pkgs-unstable`
        # threaded through. Only its config is per-user.
        pkgs-unstable.opencode
        pkgs-unstable.herdr
      ];
    };
}
