{ lib, ... }:
{
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;

      format = lib.concatStrings [
        "$directory"
        "$git_branch$git_status"
        "$nix_shell"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];

      directory = {
        truncation_length = 3;
        style             = "bold blue";
      };

      git_branch = {
        format = "[$symbol$branch]($style) ";
        style  = "bold purple";
      };

      git_status = {
        style     = "bold red";
        ahead     = "⇡\${count}";
        behind    = "⇣\${count}";
        modified  = "!\${count}";
        untracked = "?\${count}";
        staged    = "+\${count}";
      };

      nix_shell = {
        format = "[$symbol$state]($style) ";
        symbol = "󱄅 ";
        style  = "bold cyan";
      };

      cmd_duration = {
        min_time = 2000;
        format   = "took [$duration](bold yellow) ";
      };

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol   = "[❯](bold red)";
      };
    };
  };
}
