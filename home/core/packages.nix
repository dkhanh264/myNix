{
  pkgs,
  codex-cli-nix,
  antigravity-nix,
  ...
}:
{
  home.packages = with pkgs; [
    # Terminal tools
    ripgrep
    fd
    bat
    eza
    cava
    clock-rs

    # Wayland essentials
    wl-clipboard
    cliphist
    # System tray & GUI tools
    nautilus
    mesa-demos
    gnome-clocks

    # Media
    imv
    gnome-sound-recorder

    # Hardware control
    playerctl

    # Archive
    zip
    unzip

    # user apps
    discord
    discord-ptb
    spotify
    vscode
    fastfetch
    jetbrains.idea-oss
    brave
    papers
    anki
    vesktop
    localsend
    obsidian
    zoom-us
    zathura

    # dev
    jdk17
    nodejs_22
    codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli

    # Thêm các công cụ từ nixparency-dots
    walker # Thay thế Rofi làm launcher
    libqalculate # Cho module máy tính của walker

  ];
}
