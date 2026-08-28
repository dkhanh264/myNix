{ ... }:
{
  programs.zathura = {
    enable = true;

    options = {
      # Reading display optimizations
      adjust-open = "width";
      guioptions = "s"; # Statusbar only, hide scrollbars
      font = "JetBrainsMono Nerd Font 10";
      page-padding = 4;
      render-loading = false;
      selection-clipboard = "clipboard";
      database = "sqlite"; # Remember reading position

      # Smooth scrolling
      scroll-step = 60;
      scroll-page-aware = true;
      scroll-full-overlap = 0.01;

      # Dark mode / Recolor
      recolor-keephue = true;
      recolor-reverse-video = true;

      # Tokyo Night color palette
      default-bg = "#1a1b26";
      default-fg = "#c0caf5";
      statusbar-bg = "#16161e";
      statusbar-fg = "#a9b1d6";
      inputbar-bg = "#1a1b26";
      inputbar-fg = "#c0caf5";
      notification-bg = "#16161e";
      notification-fg = "#7aa2f7";
      notification-error-bg = "#f7768e";
      notification-error-fg = "#1a1b26";
      notification-warning-bg = "#e0af68";
      notification-warning-fg = "#1a1b26";
      highlight-color = "rgba(224, 175, 104, 0.4)";
      highlight-active-color = "rgba(247, 118, 142, 0.4)";
      completion-bg = "#16161e";
      completion-fg = "#a9b1d6";
      completion-group-bg = "#16161e";
      completion-group-fg = "#7aa2f7";
      completion-highlight-bg = "#283457";
      completion-highlight-fg = "#c0caf5";

      # Recolor foreground and background (Ctrl+r or i)
      recolor-darkcolor = "#c0caf5";
      recolor-lightcolor = "#1a1b26";
    };

    mappings = {
      # Navigation shortcuts
      "i" = "recolor";
      "<C-d>" = "scroll half-down";
      "<C-u>" = "scroll half-up";
      "<F11>" = "toggle_fullscreen";
    };
  };
}
