{ pkgs, lib, config, serpantinum, ... }:
let
  cfg = config.programs.serpantinum;
  jsonFormat = pkgs.formats.json { };
  userSettings = lib.filterAttrsRecursive (_: v: v != null) cfg.settings;
  userSettingsFile = jsonFormat.generate "serpantinum-user-settings.json" userSettings;
  templateSettings = builtins.fromJSON (builtins.readFile "${./config}/serpantinum/settings.json");
  mergedSettings = lib.recursiveUpdate templateSettings userSettings;
  settingsFile = jsonFormat.generate "serpantinum-settings.json" mergedSettings;
  settingsTarget = "${config.xdg.configHome}/serpantinum/settings.json";
in
{
  programs.serpantinum = {
    enable = true;
    systemd.enable = true;
    package = serpantinum.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
      postPatch = (oldAttrs.postPatch or "") + ''
        cp -rf ${./src}/. src/
        cp -rf ${./bin}/. bin/
        cp -rf ${./config}/. config/
      '';
      postFixup = (oldAttrs.postFixup or "") + ''
        for bin in serpantinum serpantinumd; do
          wrapProgram "$out/bin/$bin" \
            --prefix PATH : "${lib.makeBinPath [ pkgs.pulseaudio pkgs.xdg-user-dirs ]}"
        done
      '';
    });

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
        soundFile = "${cfg.package}/share/serpantinum/assets/sounds/notifications/Botanica.wav";
      };
      idle = {
        enabled = true;
      };
    };
  };

  systemd.user.services.serpantinum = {
    Service = {
      KillMode = lib.mkForce "process";
      TimeoutStopSec = lib.mkForce "5s";
    };
  };

  # Ensure declarative settings from Nix are merged into ~/.config/serpantinum/settings.json
  # as base defaults without overwriting runtime state (e.g. bar style, location, avatar, matugen colors).
  home.activation.serpantinumSettings = lib.mkForce (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    TARGET="${settingsTarget}"
    run mkdir -p "$(dirname "$TARGET")"
    if [ ! -e "$TARGET" ]; then
      run install -m 0644 ${settingsFile} "$TARGET"
    else
      TMP_FILE="$(mktemp)"
      if ${pkgs.jq}/bin/jq -s '.[0] * .[1]' ${settingsFile} "$TARGET" > "$TMP_FILE" 2>/dev/null && ${pkgs.jq}/bin/jq -e . "$TMP_FILE" >/dev/null 2>&1; then
        run cp "$TMP_FILE" "$TARGET"
        run chmod 0644 "$TARGET"
      fi
      rm -f "$TMP_FILE"
    fi

    STATE_DIR="${config.home.homeDirectory}/.local/state/serpantinum"
    run mkdir -p "$STATE_DIR"
    if [ ! -f "$STATE_DIR/version" ]; then
      echo "SERPANTINUM_VERSION=2.0.3" > "$STATE_DIR/version"
    fi

    QA_DIR="${config.xdg.configHome}/serpantinum/quickactions"
    run mkdir -p "$QA_DIR"
    if [ ! -f "$QA_DIR/palettes.json" ]; then
      echo "[]" > "$QA_DIR/palettes.json"
    fi
  '');
}

