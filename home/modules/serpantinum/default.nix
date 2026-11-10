{ pkgs, lib, config, serpantinum, ... }:
let
  # Smart wrapper for gpu-screen-recorder on Hybrid Intel + NVIDIA PRIME Offload setups:
  # Automatically enables NVIDIA Render Offload when the target monitor (-w <mon>) is connected to the NVIDIA dGPU (0x10de),
  # while keeping Intel iGPU (VAAPI) for internal displays (eDP-1) to save battery.
  gsrPrimeWrapper = pkgs.writeShellScriptBin "gpu-screen-recorder" ''
    target_mon=""
    prev=""
    for arg in "$@"; do
      if [ "$prev" = "-w" ]; then
        target_mon="$arg"
        break
      fi
      prev="$arg"
    done

    if [ -n "$target_mon" ]; then
      for conn in /sys/class/drm/card*-"$target_mon"; do
        if [ -r "$conn/status" ] && [ -r "$conn/../device/vendor" ]; then
          if [ "$(< "$conn/status")" = "connected" ] && [ "$(< "$conn/../device/vendor")" = "0x10de" ]; then
            export __NV_PRIME_RENDER_OFFLOAD=1
            export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
            export __GLX_VENDOR_LIBRARY_NAME=nvidia
            export __VK_LAYER_NV_optimus=NVIDIA_only
            break
          fi
        fi
      done
    fi

    exec "${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder" "$@"
  '';

  # Synchronize Serpantinum wallpaper, Matugen/preset colors, mode, and borderRadius to SDDM
  sddmSyncScript = pkgs.writeShellScriptBin "sync-sddm-serpantinum" ''
    SYNC_DIR="/var/lib/serpantinum-sddm"
    if [ ! -d "$SYNC_DIR" ] || [ ! -w "$SYNC_DIR" ]; then
      exit 0
    fi

    exec 9>"$SYNC_DIR/.sync.lock"
    ${pkgs.util-linux}/bin/flock -w 5 9 || exit 0

    exec "${pkgs.python3}/bin/python3" - << 'PYEOF'
import glob
import json
import os
import shutil

home = os.path.expanduser("~")
sync_dir = "/var/lib/serpantinum-sddm"
settings_path = os.path.join(home, ".config/serpantinum/settings.json")
palette_path = os.path.join(home, ".local/state/serpantinum/matugen/palette.json")
qs_colors_path = os.path.join(home, ".local/state/serpantinum/qs_colors.json")
wp_cache_dir = os.path.join(home, ".cache/serpantinum/wallpaper")

def load_json(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}

settings = load_json(settings_path)
palette = load_json(palette_path)
qs_colors = load_json(qs_colors_path)

theme_cfg = settings.get("theme", {}) if isinstance(settings.get("theme"), dict) else {}
lock_cfg = settings.get("lockscreen", {}) if isinstance(settings.get("lockscreen"), dict) else {}

mode = str(theme_cfg.get("mode") or palette.get("mode") or "dark").strip().lower()
if mode not in ("dark", "light", "auto"):
    mode = "dark"

border_radius = theme_cfg.get("borderRadius", 10)
try:
    border_radius = int(border_radius)
except Exception:
    border_radius = 10

wp_source = ""
if lock_cfg.get("backgroundMode") == "custom":
    custom_bg = str(lock_cfg.get("customBackground") or "").strip()
    if custom_bg.startswith("file://"):
        custom_bg = custom_bg[7:]
    if custom_bg and os.path.isfile(custom_bg):
        wp_source = custom_bg

if not wp_source:
    candidates = [os.path.join(wp_cache_dir, "current_eDP-1")] + sorted(
        glob.glob(os.path.join(wp_cache_dir, "current_*"))
    )
    for c in candidates:
        if c.endswith("_name") or c.endswith(".png") or c.endswith(".json"):
            continue
        if os.path.isfile(c):
            try:
                with open(c, "r", encoding="utf-8") as f:
                    target = f.read().strip()
                if target and os.path.isfile(target):
                    wp_source = target
                    break
            except Exception:
                pass

if not wp_source and isinstance(palette.get("image"), str):
    img = palette["image"].strip()
    if img and os.path.isfile(img):
        wp_source = img

snapshot_png = os.path.join(wp_cache_dir, "current_wallpaper.png")
video_exts = (".mp4", ".mkv", ".mov", ".webm")
bg_dest = ""

if wp_source and os.path.isfile(wp_source) and not wp_source.lower().endswith(video_exts):
    ext = os.path.splitext(wp_source)[1].lower() or ".png"
    dest = os.path.join(sync_dir, "wallpaper" + ext)
    tmp = dest + ".tmp"
    shutil.copyfile(wp_source, tmp)
    os.chmod(tmp, 0o644)
    os.replace(tmp, dest)
    bg_dest = dest
elif os.path.isfile(snapshot_png):
    dest = os.path.join(sync_dir, "wallpaper.png")
    tmp = dest + ".tmp"
    shutil.copyfile(snapshot_png, tmp)
    os.chmod(tmp, 0o644)
    os.replace(tmp, dest)
    bg_dest = dest

if bg_dest:
    for old_file in glob.glob(os.path.join(sync_dir, "wallpaper.*")):
        if old_file != bg_dest and not old_file.endswith(".tmp"):
            try:
                os.remove(old_file)
            except Exception:
                pass

colors = palette.get("colors", {}) if isinstance(palette.get("colors"), dict) else {}

def md3_color(role, variant, fallback):
    entry = colors.get(role)
    if isinstance(entry, dict):
        sub = entry.get(variant) or entry.get("default")
        if isinstance(sub, dict):
            val = sub.get("color") or sub.get("hex")
            if isinstance(val, str) and val.strip():
                return val.strip()
        elif isinstance(sub, str) and sub.strip():
            return sub.strip()
    return fallback

qsc = qs_colors.get("colors", qs_colors) if isinstance(qs_colors, dict) else {}
def qsc_str(key, fallback):
    v = qsc.get(key)
    if isinstance(v, str) and v.strip():
        return v.strip()
    if isinstance(v, dict):
        for k in ("hex", "color"):
            if isinstance(v.get(k), str) and v.get(k).strip():
                return v.get(k).strip()
    return fallback

dark_text = md3_color("on_surface", "dark", qsc_str("text", "#EEE3FD"))
light_text = md3_color("on_surface", "light", "#3A2656")

dark_primary = md3_color("primary", "dark", qsc_str("blue", "#CBA6F7"))
light_primary = md3_color("primary", "light", "#4A2C72")

dark_secondary = md3_color("secondary", "dark", qsc_str("green", "#B392E6"))
light_secondary = md3_color("secondary", "light", "#6B4A99")

dark_surface_solid = md3_color("surface_container", "dark", qsc_str("surface0", "#241636"))
light_surface_solid = md3_color("surface_container", "light", "#F3EBFC")

dark_surface_hover = md3_color("surface_container_high", "dark", qsc_str("surface1", "#33214F"))
light_surface_hover = md3_color("surface_container_high", "light", "#E4D4F9")

dark_field_box = md3_color("surface_container_highest", "dark", qsc_str("surface2", "#46306C"))
light_field_box = md3_color("surface_container_highest", "light", "#D6BFF8")

dark_on_accent = md3_color("on_primary", "dark", qsc_str("crust", "#1E1233"))
light_on_accent = md3_color("on_primary", "light", "#F3EBFC")

dark_error = md3_color("error", "dark", qsc_str("red", "#ff6b7a"))
light_error = md3_color("error", "light", "#ea1821")

conf_lines = [
    "[General]",
    f"mode={mode}",
    "font=Google-Sans",
    f"borderRadius={border_radius}",
    f"background={bg_dest}",
    f"darkText={dark_text}",
    f"lightText={light_text}",
    f"darkPrimary={dark_primary}",
    f"lightPrimary={light_primary}",
    f"darkSecondary={dark_secondary}",
    f"lightSecondary={light_secondary}",
    f"darkSurfaceSolid={dark_surface_solid}",
    f"lightSurfaceSolid={light_surface_solid}",
    f"darkSurfaceHover={dark_surface_hover}",
    f"lightSurfaceHover={light_surface_hover}",
    f"darkField={dark_surface_hover}",
    f"lightField={light_surface_hover}",
    f"darkFieldBox={dark_field_box}",
    f"lightFieldBox={light_field_box}",
    f"darkOnAccent={dark_on_accent}",
    f"lightOnAccent={light_on_accent}",
    f"darkError={dark_error}",
    f"lightError={light_error}",
    f"darkBusy={dark_primary}",
    f"lightBusy={light_primary}",
    f"darkMenu1={dark_secondary}",
    f"lightMenu1={light_secondary}",
    f"darkMenu2={dark_primary}",
    f"lightMenu2={light_primary}",
    "",
]

conf_path = os.path.join(sync_dir, "theme.conf")
conf_tmp = conf_path + ".tmp"
with open(conf_tmp, "w", encoding="utf-8") as f:
    f.write("\n".join(conf_lines))
os.chmod(conf_tmp, 0o644)
os.replace(conf_tmp, conf_path)
PYEOF
  '';

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

      # 2. Note: ScreenshotOverlay TypeError fix is included in upstream serpantinum 2.2.6

      # 3. Note: inotifywait process leak fix is already included in upstream serpantinum 2.2.4 (InfoFace.qml & SideInfoFace.qml)

      # 4. Note: Dynamic workspace count & occupancy logic are handled upstream by NiriState singleton in serpantinum 2.2.6.
      # Fix Niri workspace click focus for multi-monitor setup
      substituteInPlace src/quickshell/bar/faces/workspaces/WorkspacesFace.qml \
        --replace-fail '        if (Compositor.name === "niri") {
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", wsId.toString()]);' \
'        if (Compositor.name === "niri") {
            let sName = (barWindow && barWindow.screen && barWindow.screen.name) ? barWindow.screen.name : "";
            if (sName !== "") {
                Quickshell.execDetached(["bash", "-c", "niri msg action focus-monitor \"" + sName + "\" && niri msg action focus-workspace " + wsId]);
            } else {
                Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", wsId.toString()]);
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

      substituteInPlace src/assets/matugen/apps/btop/app.json \
        --replace-fail '"icon": "󰄪",' '"icon": "󰄪",
  "default": true,' \
        --replace-fail '"output": "$XDG_CONFIG_HOME/btop/themes/serpantinum.theme"' \
                       '"output": "$XDG_CONFIG_HOME/btop/themes/matugen.theme"'

      substituteInPlace src/quickshell/singletons/theme/Matugen.qml \
        --replace-fail 'AppTheming.apply();' \
                       'AppTheming.apply();
                Quickshell.execDetached(["bash", "-c", "sync-sddm-serpantinum >/dev/null 2>&1 || true; killall -USR1 .kitty-wrapped 2>/dev/null || pkill -SIGUSR1 kitty 2>/dev/null || true; killall -USR2 btop 2>/dev/null || pkill -SIGUSR2 -x btop 2>/dev/null || true"]);'

      substituteInPlace src/quickshell/singletons/theme/ThemeBackend.qml \
        --replace-fail '        if (root.isMatugenTheme()) {' \
                       '        Quickshell.execDetached(["sync-sddm-serpantinum"]);
        if (root.isMatugenTheme()) {'

      # 6. Support animated GIF wallpapers in WallpaperEngine.qml & sync wallpaper to SDDM
      substituteInPlace src/quickshell/wallpaper/WallpaperEngine.qml \
        --replace-fail 'cp -f \"$2\" \"$3\" 2>/dev/null || true' \
                       'cp -f \"$2\" \"$3\" 2>/dev/null || true; sync-sddm-serpantinum >/dev/null 2>&1 || true' \
        --replace-fail 'then cp -f \"$2\" \"$6\" && cp -f \"$2\" \"$7\"; fi"' \
                       'then cp -f \"$2\" \"$6\" && cp -f \"$2\" \"$7\"; sync-sddm-serpantinum >/dev/null 2>&1 || true; fi"' \
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
                            sourceSize.width: parent.width > 0 ? Math.ceil(parent.width * (Screen.devicePixelRatio || 1)) : 0
                            sourceSize.height: parent.height > 0 ? Math.ceil(parent.height * (Screen.devicePixelRatio || 1)) : 0
                        }' \
                       'Image {
                            id: imgA
                            anchors.fill: parent
                            source: !barWindow.isVideoA && !barWindow.isAnimatedA && barWindow.pathA ? "file://" + barWindow.pathA : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: !barWindow.isVideoA && !barWindow.isAnimatedA && barWindow.pathA !== ""
                            cache: true
                            sourceSize.width: parent.width > 0 ? Math.ceil(parent.width * (Screen.devicePixelRatio || 1)) : 0
                            sourceSize.height: parent.height > 0 ? Math.ceil(parent.height * (Screen.devicePixelRatio || 1)) : 0
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
                            sourceSize.width: parent.width > 0 ? Math.ceil(parent.width * (Screen.devicePixelRatio || 1)) : 0
                            sourceSize.height: parent.height > 0 ? Math.ceil(parent.height * (Screen.devicePixelRatio || 1)) : 0
                        }' \
                       'Image {
                            id: imgB
                            anchors.fill: parent
                            source: !barWindow.isVideoB && !barWindow.isAnimatedB && barWindow.pathB ? "file://" + barWindow.pathB : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: !barWindow.isVideoB && !barWindow.isAnimatedB && barWindow.pathB !== ""
                            cache: true
                            sourceSize.width: parent.width > 0 ? Math.ceil(parent.width * (Screen.devicePixelRatio || 1)) : 0
                            sourceSize.height: parent.height > 0 ? Math.ceil(parent.height * (Screen.devicePixelRatio || 1)) : 0
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
      wrapProgram $out/bin/.serpantinum-wrapped --prefix PATH : ${lib.makeBinPath [ gsrPrimeWrapper sddmSyncScript pkgs.niri pkgs.procps pkgs.psmisc ]}
      wrapProgram $out/bin/.serpantinumd-wrapped --prefix PATH : ${lib.makeBinPath [ gsrPrimeWrapper sddmSyncScript pkgs.niri pkgs.procps pkgs.psmisc ]}
    '';
  });
in
{
  home.packages = [ sddmSyncScript ];

  home.activation.syncSddmSerpantinum = lib.hm.dag.entryAfter [ "writeBoundary" "serpantinumSettings" ] ''
    run ${sddmSyncScript}/bin/sync-sddm-serpantinum || true
  '';

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
