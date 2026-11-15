# PipeWire audio stack (output, capture, and the pulseaudio compat layer that
# most desktop apps use). On hosts that also enable `bluetooth`, wireplumber's
# BlueZ monitor gives bluetooth headsets support for free.
{ ... }:

{
  flake.nixosModules.audio = {
    # Gives PipeWire/WirePlumber realtime scheduling; without rtkit they log
    # RTKit errors and audio threads run at normal priority.
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true;
      alsa.support32Bit = true;
    };
  };
}
