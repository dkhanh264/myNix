{ pkgs, ... }:

let
  open-design = pkgs.callPackage ../../../pkgs/open-design { };
in
{
  home.packages = [
    open-design
  ];
}
