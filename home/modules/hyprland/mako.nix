{ ... }:
{
  services.mako = {
    enable = true;

    settings = {
      # Keep the notification stack visually aligned with the shell's 4 px grid.
      anchor = "top-right";
      layer = "top";
      width = 380;
      height = 152;
      outer-margin = 16;
      margin = "0,0,8,0";
      padding = 16;

      # A restrained MD3 surface: outlined, readable, and less over-rounded.
      font = "Noto Sans 10";
      format = "<b>%s</b>\\n<span size=\"small\">%b</span>";
      markup = true;
      text-alignment = "left";
      background-color = "#1B1B1FFF";
      text-color = "#E5E1E6FF";
      border-color = "#938F99FF";
      border-size = 2;
      border-radius = 16;

      icons = true;
      icon-location = "left";
      max-icon-size = 48;
      icon-border-radius = 12;

      actions = true;
      on-button-left = "invoke-default-action";
      on-button-right = "dismiss";
      on-touch = "invoke-default-action";

      default-timeout = 5500;
      ignore-timeout = false;
      history = true;
      max-history = 50;
      max-visible = 4;
      sort = "-priority";
      group-by = "app-name,category";
    };

    # The generated include owns palette-dependent colors. These criteria are
    # deliberately color-agnostic so wallpaper changes keep every state synced.
    extraConfig = ''
      include=~/.cache/wal/mako-colors.conf

      [urgency=low]
      default-timeout=3500
      border-size=1

      [urgency=normal]
      default-timeout=5500
      border-size=2

      [urgency=critical]
      default-timeout=0
      ignore-timeout=true
      border-size=3

      [actionable=true]
      border-radius=12

      [grouped]
      format=<b>%s</b> <small>· %g</small>\n<span size="small">%b</span>

      [hidden]
      format=<b>%h more notifications</b>
    '';
  };
}
