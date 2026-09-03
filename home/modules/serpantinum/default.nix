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

      # 4. Fix Niri workspaces display, monitor filtering, occupied state, dynamic count & click focus
      substituteInPlace src/quickshell/bar/modules/WorkspacesWidget.qml \
        --replace-fail 'return !workspacesWidgetRoot.niriOccupiedMap[index];' \
                       'return !!workspacesWidgetRoot.niriOccupiedMap[index];' \
        --replace-fail '    property int workspaceCount: (typeof Config !== "undefined"' \
'    property int niriMaxWorkspaceIndex: 0
    property int baseWorkspaceCount: (typeof Config !== "undefined"' \
        --replace-fail 'Math.max(2, Math.min(10, Config.rawSettings.workspaceCount)) : 8))' \
'Math.max(2, Math.min(10, Config.rawSettings.workspaceCount)) : 8))
    property int workspaceCount: (isNiri && niriMaxWorkspaceIndex > baseWorkspaceCount) ? Math.min(10, niriMaxWorkspaceIndex) : baseWorkspaceCount' \
        --replace-fail '                    let data = JSON.parse(this.text);
                    let wsList = data.workspaces || [];
                    let winList = data.windows || [];
                    let occ = {};
                    for (let i = 0; i < winList.length; i++) {
                        let win = winList[i];
                        if (win.workspace_id !== undefined && win.workspace_id !== null) {
                            occ[win.workspace_id] = true;
                        }
                    }
                    let activeIdx = 0;
                    for (let j = 0; j < wsList.length; j++) {
                        let w = wsList[j];
                        let idx = (w.idx !== undefined ? w.idx : (w.id !== undefined ? w.id : 1)) - 1;
                        if (w.is_focused || w.is_active) {
                            activeIdx = idx;
                        }
                        if (w.active_window_id !== null || occ[w.id] || occ[w.idx]) {
                            occ[idx] = true;
                        }
                    }
                    workspacesWidgetRoot.niriActiveIndex = activeIdx;
                    workspacesWidgetRoot.niriOccupiedMap = occ;' \
'                    let data = JSON.parse(this.text);
                    let wsList = data.workspaces || [];
                    let winList = data.windows || [];
                    let sName = (barWindow && barWindow.screen && barWindow.screen.name) ? barWindow.screen.name : "";
                    let myWs = wsList;
                    if (sName !== "") {
                        let filtered = wsList.filter(w => !w.output || w.output === sName);
                        if (filtered.length > 0) myWs = filtered;
                    }
                    let occupiedWsIds = {};
                    for (let i = 0; i < winList.length; i++) {
                        let win = winList[i];
                        if (win.workspace_id !== undefined && win.workspace_id !== null) {
                            occupiedWsIds[win.workspace_id] = true;
                        }
                    }
                    let occ = {};
                    let activeIdx = 0;
                    let maxWs = 0;
                    for (let j = 0; j < myWs.length; j++) {
                        let w = myWs[j];
                        let wIdx = (w.idx !== undefined ? w.idx : (w.id !== undefined ? w.id : 1));
                        if (wIdx > maxWs) maxWs = wIdx;
                        let idx = wIdx - 1;
                        if (w.is_active || (sName === "" && w.is_focused)) {
                            activeIdx = idx;
                        }
                        if (w.active_window_id !== null || occupiedWsIds[w.id] || occupiedWsIds[w.idx]) {
                            occ[idx] = true;
                        }
                    }
                    workspacesWidgetRoot.niriMaxWorkspaceIndex = maxWs;
                    workspacesWidgetRoot.niriActiveIndex = activeIdx;
                    workspacesWidgetRoot.niriOccupiedMap = occ;' \
        --replace-fail '                        if (workspacesWidgetRoot.isNiri) {
                            workspacesWidgetRoot.niriActiveIndex = wsPill.index;
                            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", wsPill.wsId.toString()]);
                        }' \
'                        if (workspacesWidgetRoot.isNiri) {
                            workspacesWidgetRoot.niriActiveIndex = wsPill.index;
                            let sName = (barWindow && barWindow.screen && barWindow.screen.name) ? barWindow.screen.name : "";
                            if (sName !== "") {
                                Quickshell.execDetached(["bash", "-c", "niri msg action focus-monitor \"" + sName + "\" && niri msg action focus-workspace " + wsPill.wsId]);
                            } else {
                                Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", wsPill.wsId.toString()]);
                            }
                        }' \
        --replace-fail '                        if (workspacesWidgetRoot.isNiri) {
                            workspacesWidgetRoot.niriActiveIndex = nextIndex;
                            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", (nextIndex + 1).toString()]);
                        }' \
'                        if (workspacesWidgetRoot.isNiri) {
                            workspacesWidgetRoot.niriActiveIndex = nextIndex;
                            let sName = (barWindow && barWindow.screen && barWindow.screen.name) ? barWindow.screen.name : "";
                            if (sName !== "") {
                                Quickshell.execDetached(["bash", "-c", "niri msg action focus-monitor \"" + sName + "\" && niri msg action focus-workspace " + (nextIndex + 1)]);
                            } else {
                                Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", (nextIndex + 1).toString()]);
                            }
                        }'

      substituteInPlace src/quickshell/bar/sidemodules/SideWorkspacesWidget.qml \
        --replace-fail 'return !sideWsRoot.niriOccupiedMap[index];' \
                       'return !!sideWsRoot.niriOccupiedMap[index];' \
        --replace-fail '    property int workspaceCount: (typeof Config !== "undefined"' \
'    property int niriMaxWorkspaceIndex: 0
    property int baseWorkspaceCount: (typeof Config !== "undefined"' \
        --replace-fail 'Math.max(2, Math.min(10, Config.rawSettings.workspaceCount)) : 8))' \
'Math.max(2, Math.min(10, Config.rawSettings.workspaceCount)) : 8))
    property int workspaceCount: (isNiri && niriMaxWorkspaceIndex > baseWorkspaceCount) ? Math.min(10, niriMaxWorkspaceIndex) : baseWorkspaceCount' \
        --replace-fail '                    let data = JSON.parse(this.text);
                    let wsList = data.workspaces || [];
                    let winList = data.windows || [];
                    let occ = {};
                    for (let i = 0; i < winList.length; i++) {
                        let win = winList[i];
                        if (win.workspace_id !== undefined && win.workspace_id !== null) {
                            occ[win.workspace_id] = true;
                        }
                    }
                    let activeIdx = 0;
                    for (let j = 0; j < wsList.length; j++) {
                        let w = wsList[j];
                        let idx = (w.idx !== undefined ? w.idx : (w.id !== undefined ? w.id : 1)) - 1;
                        if (w.is_focused || w.is_active) {
                            activeIdx = idx;
                        }
                        if (w.active_window_id !== null || occ[w.id] || occ[w.idx]) {
                            occ[idx] = true;
                        }
                    }
                    sideWsRoot.niriActiveIndex = activeIdx;
                    sideWsRoot.niriOccupiedMap = occ;' \
'                    let data = JSON.parse(this.text);
                    let wsList = data.workspaces || [];
                    let winList = data.windows || [];
                    let sName = (barWindow && barWindow.screen && barWindow.screen.name) ? barWindow.screen.name : "";
                    let myWs = wsList;
                    if (sName !== "") {
                        let filtered = wsList.filter(w => !w.output || w.output === sName);
                        if (filtered.length > 0) myWs = filtered;
                    }
                    let occupiedWsIds = {};
                    for (let i = 0; i < winList.length; i++) {
                        let win = winList[i];
                        if (win.workspace_id !== undefined && win.workspace_id !== null) {
                            occupiedWsIds[win.workspace_id] = true;
                        }
                    }
                    let occ = {};
                    let activeIdx = 0;
                    let maxWs = 0;
                    for (let j = 0; j < myWs.length; j++) {
                        let w = myWs[j];
                        let wIdx = (w.idx !== undefined ? w.idx : (w.id !== undefined ? w.id : 1));
                        if (wIdx > maxWs) maxWs = wIdx;
                        let idx = wIdx - 1;
                        if (w.is_active || (sName === "" && w.is_focused)) {
                            activeIdx = idx;
                        }
                        if (w.active_window_id !== null || occupiedWsIds[w.id] || occupiedWsIds[w.idx]) {
                            occ[idx] = true;
                        }
                    }
                    sideWsRoot.niriMaxWorkspaceIndex = maxWs;
                    sideWsRoot.niriActiveIndex = activeIdx;
                    sideWsRoot.niriOccupiedMap = occ;' \
        --replace-fail '                        if (sideWsRoot.isNiri) {
                            sideWsRoot.niriActiveIndex = wsPill.index;
                            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", wsPill.wsId.toString()]);
                        }' \
'                        if (sideWsRoot.isNiri) {
                            sideWsRoot.niriActiveIndex = wsPill.index;
                            let sName = (barWindow && barWindow.screen && barWindow.screen.name) ? barWindow.screen.name : "";
                            if (sName !== "") {
                                Quickshell.execDetached(["bash", "-c", "niri msg action focus-monitor \"" + sName + "\" && niri msg action focus-workspace " + wsPill.wsId]);
                            } else {
                                Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", wsPill.wsId.toString()]);
                            }
                        }' \
        --replace-fail '                        if (sideWsRoot.isNiri) {
                            sideWsRoot.niriActiveIndex = nextIndex;
                            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", (nextIndex + 1).toString()]);
                        }' \
'                        if (sideWsRoot.isNiri) {
                            sideWsRoot.niriActiveIndex = nextIndex;
                            let sName = (barWindow && barWindow.screen && barWindow.screen.name) ? barWindow.screen.name : "";
                            if (sName !== "") {
                                Quickshell.execDetached(["bash", "-c", "niri msg action focus-monitor \"" + sName + "\" && niri msg action focus-workspace " + (nextIndex + 1)]);
                            } else {
                                Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", (nextIndex + 1).toString()]);
                            }
                        }'
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
