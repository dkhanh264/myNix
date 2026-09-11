{ pkgs, lib, config, serpantinum, ... }:
let
  patchedSerpantinum = serpantinum.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      # 1. Fix missing getConfigDir in Caching.qml
      substituteInPlace src/quickshell/singletons/system/Caching.qml \
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
        --replace-quiet '&& inotifywait -m' '&& exec inotifywait -m' \
        --replace-fail 'recWatcher.running = false;' 'if (!recWatcher.running)'

      substituteInPlace src/quickshell/bar/sidemodules/SideInfoWidget.qml \
        --replace-quiet '&& inotifywait -m' '&& exec inotifywait -m' \
        --replace-fail 'recWatcher.running = false;' 'if (!recWatcher.running)'

      # 4. Fix Niri workspaces display, monitor filtering, occupied state, dynamic count & click focus
      substituteInPlace src/quickshell/bar/modules/WorkspacesWidget.qml \
        --replace-quiet 'return !workspacesWidgetRoot.niriOccupiedMap[index];' \
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
        --replace-quiet 'return !sideWsRoot.niriOccupiedMap[index];' \
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

      # 5. Add btop theme template to Matugen and reload btop on theme change
      cat << 'EOF' > src/assets/matugen/templates/btop.theme.template
# Matugen generated theme for btop
theme[main_bg]="{{colors.surface.default.hex}}"
theme[main_fg]="{{colors.on_surface.default.hex}}"
theme[title]="{{colors.primary.default.hex}}"
theme[hi_fg]="{{colors.primary.default.hex}}"
theme[selected_bg]="{{colors.primary.default.hex}}"
theme[selected_fg]="{{colors.on_primary.default.hex}}"
theme[inactive_fg]="{{colors.outline.default.hex}}"
theme[graph_text]="{{colors.on_surface_variant.default.hex}}"
theme[meter_bg]="{{colors.surface_container_highest.default.hex}}"
theme[proc_misc]="{{colors.tertiary.default.hex}}"
theme[cpu_box]="{{colors.primary.default.hex}}"
theme[mem_box]="{{colors.secondary.default.hex}}"
theme[net_box]="{{colors.tertiary.default.hex}}"
theme[proc_box]="{{colors.primary.default.hex}}"
theme[div_line]="{{colors.outline_variant.default.hex}}"
theme[temp_start]="{{colors.primary.default.hex}}"
theme[temp_mid]="{{colors.tertiary.default.hex}}"
theme[temp_end]="{{colors.error.default.hex}}"
theme[cpu_start]="{{colors.primary.default.hex}}"
theme[cpu_mid]="{{colors.tertiary.default.hex}}"
theme[cpu_end]="{{colors.error.default.hex}}"
theme[free_start]="{{colors.tertiary.default.hex}}"
theme[free_mid]="{{colors.secondary.default.hex}}"
theme[free_end]="{{colors.primary.default.hex}}"
theme[cached_start]="{{colors.secondary.default.hex}}"
theme[cached_mid]="{{colors.tertiary.default.hex}}"
theme[cached_end]="{{colors.primary.default.hex}}"
theme[available_start]="{{colors.secondary.default.hex}}"
theme[available_mid]="{{colors.tertiary.default.hex}}"
theme[available_end]="{{colors.primary.default.hex}}"
theme[used_start]="{{colors.primary.default.hex}}"
theme[used_mid]="{{colors.tertiary.default.hex}}"
theme[used_end]="{{colors.error.default.hex}}"
theme[download_start]="{{colors.secondary.default.hex}}"
theme[download_mid]="{{colors.tertiary.default.hex}}"
theme[download_end]="{{colors.primary.default.hex}}"
theme[upload_start]="{{colors.primary.default.hex}}"
theme[upload_mid]="{{colors.tertiary.default.hex}}"
theme[upload_end]="{{colors.secondary.default.hex}}"
theme[process_start]="{{colors.primary.default.hex}}"
theme[process_mid]="{{colors.tertiary.default.hex}}"
theme[process_end]="{{colors.error.default.hex}}"
EOF

      cat << 'EOF' >> src/assets/matugen/config.toml

[templates.btop]
input_path = "templates/btop.theme.template"
output_path = "~/.config/btop/themes/matugen.theme"
EOF

      cat << 'EOF' >> src/assets/matugen/config-static.toml

[templates.btop]
input_path = "templates/btop.theme.template"
output_path = "~/.config/btop/themes/matugen.theme"
EOF

      substituteInPlace src/quickshell/singletons/theme/Matugen.qml \
        --replace-fail 'killall -USR1 .kitty-wrapped 2>/dev/null || pkill -SIGUSR1 kitty 2>/dev/null || true' \
                       'killall -USR1 .kitty-wrapped 2>/dev/null || pkill -SIGUSR1 kitty 2>/dev/null || true; killall -USR2 btop 2>/dev/null || pkill -SIGUSR2 -x btop 2>/dev/null || true'

      substituteInPlace src/scripts/wallpaper/matugen_reload.sh \
        --replace-fail 'killall -USR1 .kitty-wrapped' \
                       'killall -USR1 .kitty-wrapped 2>/dev/null || pkill -SIGUSR1 kitty 2>/dev/null || true; killall -USR2 btop 2>/dev/null || pkill -SIGUSR2 -x btop 2>/dev/null || true'

      # 6. Support animated GIF wallpapers in WallpaperEngine.qml
      substituteInPlace src/quickshell/wallpaper/WallpaperEngine.qml \
        --replace-fail 'property bool isVideoB: false' \
                       'property bool isVideoB: false
                property bool isAnimatedA: false
                property bool isAnimatedB: false' \
        --replace-fail 'barWindow.isVideoB = false;
                            barWindow.originalFileName = "";' \
                       'barWindow.isVideoB = false;
                            barWindow.isAnimatedA = false;
                            barWindow.isAnimatedB = false;
                            barWindow.originalFileName = "";' \
        --replace-fail 'function isVideo(p) {' \
                       'function isAnimated(p) {
                    let lp = p.toLowerCase();
                    return lp.endsWith(".gif");
                }

                function isVideo(p) {' \
        --replace-fail 'let cleanPath = String(path).trim();
                    let vid = barWindow.isVideo(cleanPath);' \
                       'let cleanPath = String(path).trim();
                    let vid = barWindow.isVideo(cleanPath);
                    let anim = barWindow.isAnimated(cleanPath);' \
        --replace-fail 'barWindow.pathA = cleanPath;
                        barWindow.isVideoA = vid;
                        barWindow.activeLayer = 0;' \
                       'barWindow.pathA = cleanPath;
                        barWindow.isVideoA = vid;
                        barWindow.isAnimatedA = anim;
                        barWindow.activeLayer = 0;' \
        --replace-fail 'barWindow.pathB = cleanPath;
                        barWindow.isVideoB = vid;
                        barWindow.activeLayer = 1;' \
                       'barWindow.pathB = cleanPath;
                        barWindow.isVideoB = vid;
                        barWindow.isAnimatedB = anim;
                        barWindow.activeLayer = 1;' \
        --replace-fail 'barWindow.stopB();
                            barWindow.pathB = "";
                            barWindow.isVideoB = false;
                        } else {
                            barWindow.stopA();
                            barWindow.pathA = "";
                            barWindow.isVideoA = false;' \
                       'barWindow.stopB();
                            barWindow.pathB = "";
                            barWindow.isVideoB = false;
                            barWindow.isAnimatedB = false;
                        } else {
                            barWindow.stopA();
                            barWindow.pathA = "";
                            barWindow.isVideoA = false;
                            barWindow.isAnimatedA = false;' \
        --replace-fail 'Image {
                            id: imgA
                            anchors.fill: parent
                            source: !barWindow.isVideoA && barWindow.pathA ? "file://" + barWindow.pathA : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: !barWindow.isVideoA && barWindow.pathA !== ""
                            cache: true
                            sourceSize.width: parent.width > 0 ? parent.width : 0
                            sourceSize.height: parent.height > 0 ? parent.height : 0
                        }' \
                       'Image {
                            id: imgA
                            anchors.fill: parent
                            source: !barWindow.isVideoA && !barWindow.isAnimatedA && barWindow.pathA ? "file://" + barWindow.pathA : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: !barWindow.isVideoA && !barWindow.isAnimatedA && barWindow.pathA !== ""
                            cache: true
                            sourceSize.width: parent.width > 0 ? parent.width : 0
                            sourceSize.height: parent.height > 0 ? parent.height : 0
                        }

                        AnimatedImage {
                            id: animA
                            anchors.fill: parent
                            source: !barWindow.isVideoA && barWindow.isAnimatedA && barWindow.pathA ? "file://" + barWindow.pathA : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: !barWindow.isVideoA && barWindow.isAnimatedA && barWindow.pathA !== ""
                            cache: true
                            playing: !barWindow.playbackPaused
                            paused: barWindow.playbackPaused
                        }' \
        --replace-fail 'Image {
                            id: imgB
                            anchors.fill: parent
                            source: !barWindow.isVideoB && barWindow.pathB ? "file://" + barWindow.pathB : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: !barWindow.isVideoB && barWindow.pathB !== ""
                            cache: true
                            sourceSize.width: parent.width > 0 ? parent.width : 0
                            sourceSize.height: parent.height > 0 ? parent.height : 0
                        }' \
                       'Image {
                            id: imgB
                            anchors.fill: parent
                            source: !barWindow.isVideoB && !barWindow.isAnimatedB && barWindow.pathB ? "file://" + barWindow.pathB : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: !barWindow.isVideoB && !barWindow.isAnimatedB && barWindow.pathB !== ""
                            cache: true
                            sourceSize.width: parent.width > 0 ? parent.width : 0
                            sourceSize.height: parent.height > 0 ? parent.height : 0
                        }

                        AnimatedImage {
                            id: animB
                            anchors.fill: parent
                            source: !barWindow.isVideoB && barWindow.isAnimatedB && barWindow.pathB ? "file://" + barWindow.pathB : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: !barWindow.isVideoB && barWindow.isAnimatedB && barWindow.pathB !== ""
                            cache: true
                            playing: !barWindow.playbackPaused
                            paused: barWindow.playbackPaused
                        }'
    '';

    postFixup = (oldAttrs.postFixup or "") + ''
      wrapProgram $out/bin/serpantinum --prefix PATH : ${lib.makeBinPath [ pkgs.niri pkgs.procps pkgs.psmisc ]}
      wrapProgram $out/bin/serpantinumd --prefix PATH : ${lib.makeBinPath [ pkgs.niri pkgs.procps pkgs.psmisc ]}
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
