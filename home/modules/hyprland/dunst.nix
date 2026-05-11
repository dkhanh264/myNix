{ ... }:
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        width         = 300;
        height        = 100;
        origin        = "top-right";
        offset        = "10x10";
        font          = "JetBrainsMono Nerd Font 11";
        corner_radius = 10;
        frame_width   = 2;
        frame_color   = "#89b4fa";
        background    = "#1e1e2e";
        foreground    = "#cdd6f4";
        timeout       = 5;
      };
      urgency_low      = { frame_color = "#6c7086"; };
      urgency_normal   = { frame_color = "#89b4fa"; };
      urgency_critical = { frame_color = "#f38ba8"; timeout = 0; };
    };
  };
}
