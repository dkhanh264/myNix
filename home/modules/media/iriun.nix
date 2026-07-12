{ pkgs, ... }:

let
  iriunwebcam = pkgs.callPackage ../../../pkgs/iriunwebcam { };
in
{
  home.packages = with pkgs; [
    iriunwebcam
    v4l-utils
  ];
}
