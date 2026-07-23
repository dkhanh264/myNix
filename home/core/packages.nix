{ pkgs, codex-cli-nix, ... }:
{
  home.packages = with pkgs; [
    # Terminal tools
    ripgrep
    fd
    bat
    eza
    fzf
    zoxide
    cava
    clock-rs

    # Wayland essentials
    wl-clipboard
    cliphist
    grim
    slurp

    # System tray & GUI tools
    networkmanagerapplet
    pavucontrol
    nautilus
    mesa-demos
    nwg-look
    gnome-clocks

    # Media
    imv
    gnome-sound-recorder
    gpu-screen-recorder

    # Hardware control
    brightnessctl
    playerctl

    # Archive
    zip
    unzip

    # user apps
    discord
    spotify
    vscode
    fastfetch
    jetbrains.idea-oss
    brave
    papers
    anki
    vesktop
    localsend
    droidcam

    # dev 
    jdk17
    nodejs_22
    codex-cli-nix.packages.${pkgs.system}.default

  

    # Thêm các công cụ từ nixparency-dots
    walker         # Thay thế Rofi làm launcher
    mako           # Thay thế Dunst làm notification daemon
    swaybg         # Đặt hình nền tĩnh (dự phòng)
    swww           # Đặt hình nền tĩnh với hiệu ứng chuyển cảnh
    mpvpaper       # Đặt hình nền động (video)
    ffmpeg         # Cần cho script trích xuất ảnh từ video
    libqalculate   # Cho module máy tính của walker
    jq             # Cần cho các script xử lý JSON
    libnotify
    
  ];
}

