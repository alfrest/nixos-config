# Games for the alfrest user. Opt-in per host: GUI hosts that want games
# import `games` explicitly (currently only `lap`).
{ ... }:

{
  flake.nixosModules.games =
    { pkgs, ... }:
    {
      home-manager.users.alfrest.home.packages = with pkgs; [
        openttd
      ];
    };
}
