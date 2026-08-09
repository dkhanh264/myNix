{ pkgs, ... }:
let
  walkerMenu = pkgs.writeShellApplication {
    name = "walker-menu";
    runtimeInputs = [ pkgs.walker ];
    text = ''
      case "''${1:-apps}" in
        apps) exec walker --theme transparent-apps ;;
        *)
          printf 'Usage: walker-menu apps\n' >&2
          exit 2
          ;;
      esac
    '';
  };

in
{
  home.packages = [ walkerMenu ];

  xdg.configFile."walker" = {
    source = ./walker;
    recursive = true;
    force = true;
  };
}
