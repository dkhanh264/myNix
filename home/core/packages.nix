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
    pulseaudio
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

  ];
}

