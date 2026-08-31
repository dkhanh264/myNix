{ serpantinum, ... }:
{
  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile "${serpantinum}/config/kitty/kitty.conf";
  };
}

