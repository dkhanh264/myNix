{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Terminal tools
    ripgrep
    fd
    bat
    eza
    fzf
    zoxide
    btop

    # Wayland essentials
    wl-clipboard
    cliphist
    grim
    slurp

    # System tray & GUI tools
    networkmanagerapplet
    blueman
    pavucontrol
    nautilus
    mesa-demos
    nwg-look

    # Media
    mpv
    imv

    # Hardware control
    brightnessctl
    playerctl

    # Archive
    zip
    unzip

    # user apps
    firefox
    google-chrome
    discord
    spotify
    vscode
    fastfetch
    steam

    # Thêm các công cụ từ nixparency-dots
    walker         # Thay thế Rofi làm launcher
    mako           # Thay thế Dunst làm notification daemon
    swaybg         # Đặt hình nền tĩnh
    mpvpaper       # Đặt hình nền động (video)
    ffmpeg         # Cần cho script trích xuất ảnh từ video
    libqalculate   # Cho module máy tính của walker
    jq             # Cần cho các script xử lý JSON
    libnotify
    
  ];
}

