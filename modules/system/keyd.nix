{ ... }:

{
  flake.nixosModules.keyd =
    { ... }:
    {
      services.keyd = {
        enable = true;

        # No `ids` here — the default is [ "*" ], so the config applies
        # to every keyboard.
        keyboards.default.settings = {
          global = {
            overload_tap_timeout = 200;
          };

          main = {
            capslock = "overload(altgr, esc)";
            rightalt = "layer(alt)";
            # Quoted: not a valid Nix identifier.
            "f23+leftshift+leftmeta" = "layer(meta)";
          };
        };
      };
    };
}
