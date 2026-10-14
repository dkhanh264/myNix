{ pkgs, ... }:
{
  imports = [
    ./niri.nix
    ./hypridle.nix
  ];

  systemd.user.services.eco-daemon = {
    Unit = {
      Description = "Eco Power Management Daemon (Auto AC/Battery Profile Switcher)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.callPackage ../../../pkgs/eco { }}/bin/eco daemon";
      Restart = "always";
      RestartSec = "5s";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
