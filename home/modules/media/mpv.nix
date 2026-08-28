{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;

    config = {
      vo = "gpu";
      profile = "gpu-hq";
      gpu-context = "wayland";

      # Hardware-accelerated decoding
      hwdec = "auto-safe";

      keep-open = "yes";
      save-position-on-quit = true;
      cursor-autohide = 1000;

      # Subtitle and audio language priority
      slang = "eng,vie";
      alang = "eng,jpn,vie";
    };

    scripts = with pkgs.mpvScripts; [
      # Media keys integration via MPRIS protocol
      mpris

      # Floating control bar and thumbnail scrubbing
      uosc
      thumbfast
    ];
  };
}
