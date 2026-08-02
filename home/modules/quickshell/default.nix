{ config, pkgs, ... }:

{
  # Keep every command used by the control center in the same module. Nix
  # deduplicates packages that are also required elsewhere in the home config.
  home.packages = with pkgs; [
    quickshell
    gpu-screen-recorder
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

  xdg.configFile."quickshell" = {
    source = config.lib.file.mkOutOfStoreSymlink "/home/dk/Test/myNix/home/modules/quickshell/config";
    force = true;
  };

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell Desktop Shell";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Environment = [
        "PATH=${pkgs.gpu-screen-recorder}/bin:/run/wrappers/bin:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
        "QSG_RENDER_LOOP=threaded"
      ];
      Restart = "on-failure";
      RestartSec = "1s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
