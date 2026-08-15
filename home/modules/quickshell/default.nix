{ config, pkgs, ... }:
let
  m3PowerProfile = pkgs.callPackage ../m3-power-profile { };
in

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
    ffmpeg
    m3PowerProfile
  ];

  xdg.configFile."quickshell" = {
    source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/home/modules/quickshell/config";
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
        "PATH=${m3PowerProfile}/bin:${pkgs.gpu-screen-recorder}/bin:/run/wrappers/bin:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
        "MALLOC_TRIM_THRESHOLD_=131072"
        "MALLOC_MMAP_THRESHOLD_=131072"
        "QML_DISABLE_DISK_CACHE=0"
      ];
      Restart = "on-failure";
      RestartSec = "1s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
