{ pkgs, spicetify-nix, ... }:

let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.spicetify = {
    enable = true;

    # Theme cấu hình (có thể đổi sang theme khác như dracula, nord, sleek, text, v.v.)
    theme = spicePkgs.themes.starryNight;
    colorScheme = "Base";

    # Các tiện ích mở rộng hữu ích
    enabledExtensions = with spicePkgs.extensions; [
      adblockify # Chặn quảng cáo
      shuffle # Shuffle ngẫu nhiên thực sự
      playlistIcons # Icon cho playlist
      fullAppDisplay # Toàn màn hình đẹp
    ];

    # Các ứng dụng tùy chỉnh tích hợp vào sidebar
    enabledCustomApps = with spicePkgs.apps; [
      marketplace # Cửa hàng theme/extension trực quan trong Spotify
      lyricsPlus # Hiển thị lời bài hát nâng cao (đồng bộ, dịch)
    ];
  };
}
