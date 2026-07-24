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
    curl
  ];

  xdg.configFile."quickshell".source = ./config;

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell Desktop Shell";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
      RestartSec = "1s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
