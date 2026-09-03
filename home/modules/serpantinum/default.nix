{ pkgs, lib, config, serpantinum, ... }:
let
  patchedSerpantinum = serpantinum.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      # 1. Fix missing getConfigDir in Caching.qml
      substituteInPlace src/quickshell/singletons/Caching.qml \
        --replace-fail 'readonly property string cacheDir:' \
'readonly property string configDir: Quickshell.env("QS_CONFIG_DIR") ? Quickshell.env("QS_CONFIG_DIR") : (home + "/.config/serpantinum")

    function getConfigDir(widgetName) {
        if (!widgetName || widgetName === "serpantinum" || configDir.endsWith("/" + widgetName)) {
            Quickshell.execDetached(["mkdir", "-p", configDir]);
            return configDir;
        }
        var envPath = Quickshell.env("QS_CONFIG_" + widgetName.toUpperCase());
        var finalPath = envPath ? envPath : (configDir + "/" + widgetName);
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }

    readonly property string cacheDir:'

      # 2. Fix TypeError in ScreenshotOverlay.qml when onLoaded has no data arg
      substituteInPlace src/quickshell/screenshot/ScreenshotOverlay.qml \
        --replace-fail 'let content = data.trim();' \
                       'let content = (typeof data !== "undefined" && data ? data : text()).trim();'

      # 3. Fix inotifywait process leak in InfoWidget.qml & SideInfoWidget.qml
      substituteInPlace src/quickshell/bar/modules/InfoWidget.qml \
        --replace-fail '&& inotifywait -m' '&& exec inotifywait -m' \
        --replace-fail 'recWatcher.running = false;' 'if (!recWatcher.running)'

      substituteInPlace src/quickshell/bar/sidemodules/SideInfoWidget.qml \
        --replace-fail '&& inotifywait -m' '&& exec inotifywait -m' \
        --replace-fail 'recWatcher.running = false;' 'if (!recWatcher.running)'
    '';

    postFixup = (oldAttrs.postFixup or "") + ''
      wrapProgram $out/bin/serpantinum --prefix PATH : ${lib.makeBinPath [ pkgs.niri ]}
      wrapProgram $out/bin/serpantinumd --prefix PATH : ${lib.makeBinPath [ pkgs.niri ]}
    '';
  });
in
{
  programs.serpantinum = {
    enable = true;
    package = patchedSerpantinum;
    systemd.enable = true;

    settings = {
      wallpaperDir = "${config.home.homeDirectory}/Pictures/wallpapers";
      bar = {
        position = "top";
        style = "modular";
        time = {
          format = "HH:mm:ss";
        };
      };
      theme = {
        fontFamily = "JetBrains Mono";
        borderRadius = 10;
        matugen = true;
      };
      notifications = {
        dnd = false;
        position = "top right";
        sound = true;
      };
      idle = {
        enabled = true;
      };
    };
  };
}
