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
    trash-cli

    # Wayland essentials
    wl-clipboard
    cliphist

    # System tray & GUI tools
    nautilus
    mesa-demos
    gnome-clocks

    # Media & Recording
    imv
    gnome-sound-recorder
    wf-recorder
    gpu-screen-recorder

    # Hardware control & Audio GUI
    playerctl
    brightnessctl
    pavucontrol
    pulseaudio

    # Archive
    zip
    unzip

    # user apps
    discord-ptb
    spotify
    fastfetch
    jetbrains.idea
    brave
    papers
    anki
    weka
    localsend

    (pkgs.callPackage ../../pkgs/davinci-resolve { })

    # dev
    jdk17
    nodejs_22
    codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
  ];
}
