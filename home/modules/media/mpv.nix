{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;

    config = {
      vo = "gpu";
      profile = "gpu-hq";
      gpu-context = "wayland";

      # Tự động kích hoạt giải mã phần cứng phù hợp với driver hiện tại.
      hwdec = "auto-safe";

      keep-open = "yes";
      save-position-on-quit = true;
      cursor-autohide = 1000;

      # Ưu tiên ngôn ngữ cho phụ đề và âm thanh.
      slang = "eng,vie";
      alang = "eng,jpn,vie";
    };

    scripts = with pkgs.mpvScripts; [
      # Tích hợp phím Media qua giao thức MPRIS.
      mpris

      # Thanh điều khiển nổi và ảnh thu nhỏ khi tua video.
      uosc
      thumbfast
    ];
  };
}
