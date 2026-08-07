{ pkgs, ... }:

{
  imports = [
    ./git.nix
    ./nixvim.nix
  ];

  programs.vscode = {
    enable = true;
    profiles.default.userSettings = {
      # Memory & Performance Optimizations for VS Code
      "telemetry.telemetryLevel" = "off";
      "typescript.tsc.autoDetect" = "off";
      "javascript.tsc.autoDetect" = "off";
      "npm.autoDetect" = "off";
      "search.followSymlinks" = false;
      "git.autofetch" = false;
      "workbench.startupEditor" = "none";
      
      # Exclude build output and large dirs from file watching (saves RAM)
      "files.watcherExclude" = {
        "**/.git/objects/**" = true;
        "**/.git/subtree-cache/**" = true;
        "**/node_modules/*/**" = true;
        "**/.hg/store/**" = true;
        "**/target/**" = true;
        "**/.next/**" = true;
        "**/dist/**" = true;
        "**/result/**" = true;
        "**/.direnv/**" = true;
      };

      # Exclude search indexing in build outputs
      "search.exclude" = {
        "**/node_modules" = true;
        "**/bower_components" = true;
        "**/*.code-search" = true;
        "**/target" = true;
        "**/.next" = true;
        "**/dist" = true;
        "**/result" = true;
      };
    };
  };
}
