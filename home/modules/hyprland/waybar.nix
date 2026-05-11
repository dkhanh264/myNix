{ ... }:
{
  programs.waybar = {
    enable = true;

    settings.mainBar = {
      layer    = "top";
      position = "top";
      height   = 32;
      spacing  = 4;

      modules-left   = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right  = ["custom/weather" "cpu" "memory" "pulseaudio" "network" "battery" "tray" ];

      "hyprland/workspaces" = {
        on-click     = "activate";
        format       = "{icon}";
        format-icons = {
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          "6" = "6";
          "7" = "7";
          "8" = "8";
          "9" = "9";
          "10" = "10";
          urgent = "!";
          default = "•";
        };
      };

      "hyprland/window" = {
        max-length       = 60;
        separate-outputs = true;
      };

      clock = {
        format     = "  {:%H:%M}";
        format-alt = "  {:%A, %d/%m/%Y}";
      };

      "custom/weather" = {
        "exec" = "curl -s 'wttr.in/Ho_Chi_Minh?format=%C+%t'";
        "interval" = 1800;
        "format" = "{}";
      };

      cpu = {
        format   = " {usage}%";
        interval = 2;
        tooltip  = false;
      };

      memory = {
        format   = " {}%";
        interval = 2;
      };

      battery = {
        states          = { warning = 30; critical = 15; };
        format          = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged  = "󰚥 {capacity}%";
        format-icons    = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
      };

      network = {
        format-wifi         = " {signalStrength}%";
        format-ethernet     = "󰈀 Connected";
        format-disconnected = "󰤭 Offline";
        on-click            = "nm-connection-editor";
      };

      pulseaudio = {
        format       = "{icon} {volume}%";
        format-muted = "󰝟 Muted";
        format-icons = { default = [ "" "" "" ]; };
        on-click     = "pavucontrol";
      };

      tray.spacing = 10;
    };

    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", monospace;
        font-size: 13px;
        min-height: 0;
        border: none;
        border-radius: 0;
      }
      window#waybar {
        background-color: rgba(17, 17, 27, 0.9);
        color: #cdd6f4;
        border-bottom: 2px solid rgba(137, 180, 250, 0.3);
      }
      #workspaces button {
        padding: 2px 8px;
        color: #6c7086;
        background: transparent;
        border-radius: 6px;
        margin: 4px 2px;
        transition: all 0.2s ease;
      }
      #workspaces button.active {
        color: #89b4fa;
        background: rgba(137, 180, 250, 0.15);
        border-bottom: 2px solid #89b4fa;
      }
      #workspaces button:hover {
        color: #cdd6f4;
        background: rgba(205, 214, 244, 0.1);
      }
      #workspaces button.urgent { color: #f38ba8; }
      #window     { color: #a6adc8; padding: 0 10px; }
      #clock      { color: #cba6f7; padding: 0 10px; font-weight: bold; }
      #cpu        { color: #f38ba8; padding: 0 8px; }
      #memory     { color: #fab387; padding: 0 8px; }
      #battery    { color: #a6e3a1; padding: 0 8px; }
      #network    { color: #94e2d5; padding: 0 8px; }
      #pulseaudio { color: #89dceb; padding: 0 8px; }
      #tray       { padding: 0 8px; }
      #battery.warning  { color: #f9e2af; }
      #battery.critical { color: #f38ba8; }
    '';
  };
}
