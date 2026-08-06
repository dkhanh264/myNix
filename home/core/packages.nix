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

    # dev
    jdk17
    nodejs_22
    codex-cli-nix.packages.${pkgs.system}.default
    antigravity-nix.packages.${pkgs.system}.google-antigravity-cli

    # Thêm các công cụ từ nixparency-dots
    walker # Thay thế Rofi làm launcher
    libqalculate # Cho module máy tính của walker

  ];
}
