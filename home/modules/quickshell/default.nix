{ pkgs, ... }:

{
  # Keep every command used by the control center in the same module. Nix
  # deduplicates packages that are also required elsewhere in the home config.
  home.packages = with pkgs; [
    quickshell
    brightnessctl
    networkmanager
    networkmanagerapplet
    wireplumber
    power-profiles-daemon
    pavucontrol
    blueman
    nwg-look
  ];

  xdg.configFile."quickshell".source = ./config;
}
