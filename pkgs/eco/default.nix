{ pkgs }:

let
  ecoScript = pkgs.writeShellScriptBin "eco" (builtins.readFile ./eco.sh);
in
pkgs.symlinkJoin {
  name = "eco-tools";
  paths = [ ecoScript ];
  postBuild = ''
    ln -s $out/bin/eco $out/bin/hz
  '';
}
