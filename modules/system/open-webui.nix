{ config, ... }:

{
  flake.nixosModules.open-webui =
    { config, lib, ... }:
    {
      # Open WebUI is unfree; whitelist only this package instead of enabling
      # `allowUnfree` for the host.
      nixpkgs.config.allowUnfreePredicate =
        pkg: builtins.elem (lib.getName pkg) [ "open-webui" ];

      # The API key never appears in `environment`; it is rendered into an env
      # file at activation so the value stays out of the Nix store.
      sops.secrets."opencode-api-key" = {
        sopsFile = ../../secrets/srv.yaml;
        key = "opencode-api-key";
      };

      sops.templates."open-webui-env" = {
        content = "OPENAI_API_KEY=${config.sops.placeholder."opencode-api-key"}\n";
        restartUnits = [ "open-webui.service" ];
      };

      # The connection can also be changed in the web UI, where it is persisted
      # in `stateDir`; these values only seed a fresh database.
      services.open-webui = {
        enable = true;
        host = "0.0.0.0";
        port = 8787;
        openFirewall = true;
        environmentFile = config.sops.templates."open-webui-env".path;
        environment = {
          # OpenCode's gateway exposes an OpenAI-compatible API; the plural
          # variant is the one current releases read, the singular is kept for
          # older code paths.
          OPENAI_API_BASE_URL = "https://opencode.ai/zen/go/v1";
          OPENAI_API_BASE_URLS = "https://opencode.ai/zen/go/v1";
          ENABLE_OLLAMA_API = "False";
        };
      };
    };
}
