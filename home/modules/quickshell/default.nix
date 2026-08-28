{ pkgs, ... }:
{
  home.packages = with pkgs; [
    quickshell
  ];

  xdg.configFile."quickshell".source = ./config;

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell desktop components";
      Documentation = "https://quickshell.outfoxxed.me";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
