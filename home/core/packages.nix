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

    # Media
    imv
    gnome-sound-recorder

    # Hardware control & Audio GUI
    playerctl
    brightnessctl
    pavucontrol

    # Archive
    zip
    unzip

    # user apps
    discord
    discord-ptb
    spotify
    fastfetch
    jetbrains.idea
    brave
    papers
    anki

    (pkgs.symlinkJoin {
      name = "davinci-resolve";
      paths = [ pkgs.davinci-resolve ];

      nativeBuildInputs = [ pkgs.makeWrapper ];

      postBuild = ''
        wrapProgram $out/bin/davinci-resolve \
          --set QT_QPA_PLATFORM xcb
      '';
    })

    # dev
    jdk17
    nodejs_22
    codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
    antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system}.google-antigravity-cli
  ];
}
