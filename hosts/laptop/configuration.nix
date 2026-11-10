{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  sddmSerpantinumTheme = pkgs.stdenv.mkDerivation {
    pname = "sddm-serpantinum-theme";
    version = "2.4.3";
    src = "${inputs.serpantinum}/config/sddm/themes";
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes $out/share/fonts/truetype
      cp -r material-you $out/share/sddm/themes/
      chmod -R u+w $out/share/sddm/themes/material-you
      cp -f material-you/font/*.ttf $out/share/fonts/truetype/

      substituteInPlace $out/share/sddm/themes/material-you/Main.qml \
        --replace-fail 'readonly property real radius: 10 * s' \
                       'function cfgStr(key, fallback) { return (typeof config !== "undefined" && config[key] !== undefined && String(config[key]).trim() !== "") ? String(config[key]).trim() : fallback; }
    function cfgNum(key, fallback) { if (typeof config !== "undefined" && config[key] !== undefined && String(config[key]).trim() !== "") { let n = Number(config[key]); if (!isNaN(n)) return n; } return fallback; }
    readonly property real radius: cfgNum("borderRadius", 10) * s
    readonly property string customBg: cfgStr("background", "")
    readonly property bool customBgIsGif: customBg.toLowerCase().endsWith(".gif")' \
        --replace-fail 'readonly property color cText: isDark ? "#EEE3FD" : "#3A2656"' \
                       'readonly property color cText: isDark ? cfgStr("darkText", "#EEE3FD") : cfgStr("lightText", "#3A2656")' \
        --replace-fail 'readonly property color cDark: isDark ? "#CBA6F7" : "#4A2C72"' \
                       'readonly property color cDark: isDark ? cfgStr("darkPrimary", "#CBA6F7") : cfgStr("lightPrimary", "#4A2C72")' \
        --replace-fail 'readonly property color cMid: isDark ? "#B392E6" : "#6B4A99"' \
                       'readonly property color cMid: isDark ? cfgStr("darkSecondary", "#B392E6") : cfgStr("lightSecondary", "#6B4A99")' \
        --replace-fail 'readonly property color cSurface: isDark ? Qt.rgba(0.125, 0.082, 0.2, 0.9) : Qt.rgba(0.953, 0.922, 0.988, 0.92)' \
                       'readonly property color cSurface: Qt.rgba(cSurfaceSolid.r, cSurfaceSolid.g, cSurfaceSolid.b, isDark ? 0.90 : 0.92)' \
        --replace-fail 'readonly property color cSurfaceHover: isDark ? "#33214F" : "#E4D4F9"' \
                       'readonly property color cSurfaceHover: isDark ? cfgStr("darkSurfaceHover", "#33214F") : cfgStr("lightSurfaceHover", "#E4D4F9")' \
        --replace-fail 'readonly property color cField: isDark ? "#33214F" : "#E4D4F9"' \
                       'readonly property color cField: isDark ? cfgStr("darkField", "#33214F") : cfgStr("lightField", "#E4D4F9")' \
        --replace-fail 'readonly property color cFieldBox: isDark ? "#46306C" : "#D6BFF8"' \
                       'readonly property color cFieldBox: isDark ? cfgStr("darkFieldBox", "#46306C") : cfgStr("lightFieldBox", "#D6BFF8")' \
        --replace-fail 'readonly property color cSurfaceSolid: isDark ? "#241636" : "#F3EBFC"' \
                       'readonly property color cSurfaceSolid: isDark ? cfgStr("darkSurfaceSolid", "#241636") : cfgStr("lightSurfaceSolid", "#F3EBFC")' \
        --replace-fail 'readonly property color cOnAccent: isDark ? "#1E1233" : "#F3EBFC"' \
                       'readonly property color cOnAccent: isDark ? cfgStr("darkOnAccent", "#1E1233") : cfgStr("lightOnAccent", "#F3EBFC")' \
        --replace-fail 'readonly property color cRed: isDark ? "#ff6b7a" : "#ea1821"' \
                       'readonly property color cRed: isDark ? cfgStr("darkError", "#ff6b7a") : cfgStr("lightError", "#ea1821")' \
        --replace-fail 'readonly property color cBusy: isDark ? "#CBA6F7" : "#8A67BD"' \
                       'readonly property color cBusy: isDark ? cfgStr("darkBusy", "#CBA6F7") : cfgStr("lightBusy", "#8A67BD")' \
        --replace-fail 'readonly property color cMenu1: isDark ? "#B392E6" : "#6B4A99"' \
                       'readonly property color cMenu1: isDark ? cfgStr("darkMenu1", "#B392E6") : cfgStr("lightMenu1", "#6B4A99")' \
        --replace-fail 'readonly property color cMenu2: isDark ? "#CBA6F7" : "#8A67BD"' \
                       'readonly property color cMenu2: isDark ? cfgStr("darkMenu2", "#CBA6F7") : cfgStr("lightMenu2", "#8A67BD")' \
        --replace-fail 'readonly property color cMenuDanger: isDark ? "#ff6b7a" : "#ea1821"' \
                       'readonly property color cMenuDanger: isDark ? cfgStr("darkError", "#ff6b7a") : cfgStr("lightError", "#ea1821")' \
        --replace-fail 'source: root.isDark ? "bg_dark.jpg" : "bg.jpg"' \
                       'property bool customBgFailed: false
        source: (!root.customBgIsGif && root.customBg !== "" && !customBgFailed) ? (root.customBg.startsWith("/") ? "file://" + root.customBg : root.customBg) : (root.isDark ? "bg_dark.jpg" : "bg.jpg")
        cache: false
        fillMode: Image.PreserveAspectCrop
        visible: !(root.customBgIsGif && customGif.status === AnimatedImage.Ready)
        onStatusChanged: { if (status === Image.Error) customBgFailed = true; }
    }
    AnimatedImage {
        id: customGif
        anchors.fill: parent
        source: (root.customBgIsGif && root.customBg !== "") ? (root.customBg.startsWith("/") ? "file://" + root.customBg : root.customBg) : ""
        cache: false
        visible: root.customBgIsGif && root.customBg !== "" && status === AnimatedImage.Ready
        playing: visible' \
        --replace-fail 'color: root.isDark ? Qt.rgba(0, 0, 0, modelData.alpha * 1.6) : Qt.rgba(0.18, 0.1, 0.29, modelData.alpha)' \
                       'color: root.isDark ? Qt.rgba(0, 0, 0, modelData.alpha * 1.6) : Qt.rgba(root.cText.r, root.cText.g, root.cText.b, modelData.alpha)'

      rm -f $out/share/sddm/themes/material-you/theme.conf
      ln -s /var/lib/serpantinum-sddm/theme.conf $out/share/sddm/themes/material-you/theme.conf
    '';
  };
in
{
  imports = [ ./hardware-configuration.nix ];

  # ── Bootloader ─────────────────────────────────────────────────────────
  boot.loader.efi.canTouchEfiVariables = true;

  # Firewall configuration for LocalSend & custom ports
  networking.firewall.allowedUDPPorts = [
    4698
    8081
    53317 # LocalSend Multicast / UDP Discovery
  ];
  networking.firewall.allowedTCPPorts = [
    53317 # LocalSend TCP File Transfer
    8081
  ];

  # Extra module configurations
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=3 video_nr=2,3,4 card_label="Iriun Webcam,Iriun Cam 2,Iriun Cam 3" exclusive_caps=1,1,1

    # Tối ưu hóa tiết kiệm pin cho WiFi & Audio
    options iwlwifi power_save=1
    options iwlmvm power_scheme=3
    options snd_hda_intel power_save=1 power_save_controller=Y
    options snd_soc_sof power_save=1
  '';

  boot.kernelParams = [
    "pcie_aspm=force"
    "pcie_aspm.policy=powersupersave"
    "nvme_core.default_ps_max_latency_us=0" # Cho phép NVMe SSD vào trạng thái tiết kiệm điện sâu nhất (APST)
    "i915.enable_fbc=1" # Frame Buffer Compression cho Intel iGPU
    "i915.enable_psr=1" # Panel Self Refresh cho màn hình laptop
  ];

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  programs.nix-ld.enable = true;

  # Direct monitor capture uses gsr-kms-server.
  programs.gpu-screen-recorder.enable = true;

  # ── Network ────────────────────────────────────────────────────────────
  networking.hostName = "HiMeo";
  networking.networkmanager = {
    enable = true;
    wifi.powersave = true;
    insertNameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];
  };
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  # ── Locale & Timezone ──────────────────────────────────────────────────
  time.timeZone = "Asia/Ho_Chi_Minh";

  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_TIME = "en_US.UTF-8";
    };

    inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5.addons = with pkgs; [
        qt6Packages.fcitx5-unikey
        fcitx5-gtk
        qt6Packages.fcitx5-configtool
      ];
    };
  };

  # ── Fcitx5 Lotus Vietnamese Input Method ───────────────────────────────
  services.fcitx5-lotus = {
    enable = true;
    users = [ "dk" ];
  };

  # ── Android SDK ────────────────────────────────────────────────────────
  nixpkgs.config.android_sdk.accept_license = true;

  # ── NVIDIA Driver ──────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;

    # 1. Proprietary driver for multi-monitor Wayland stability.
    open = false;

    # 2. Dynamic Power Management (RTD3) - Tự động tắt dGPU (D3cold 0W) khi không dùng
    powerManagement.enable = true;
    powerManagement.finegrained = true;

    prime = {
      # Chế độ Offload: Các tác vụ thông thường (Niri, Web, Notes) chạy trên Intel iGPU tiết kiệm pin tối đa.
      # Khi cần ứng dụng/đồ họa nặng (DaVinci), chỉ cần chạy qua lệnh: nvidia-offload <app>
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.usbmuxd.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      intel-media-driver
      nvidia-vaapi-driver
      libva-utils
      libva-vdpau-driver
      libvdpau-va-gl
    ];

    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # ── Wayland & Niri ─────────────────────────────────────────────────────
  programs.niri.enable = true;
  programs.serpantinum.enable = true;


  # ── XDG Desktop Portal (File chooser, Screencast, etc.) ────────────────
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config = {
      common = {
        default = [ "gtk" ];
      };
      niri = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      };
    };
  };

  security.polkit.enable = true;
  security.sudo.extraRules = [
    {
      users = [ "dk" ];
      commands = [
        {
          command = "${pkgs.iw}/bin/iw";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
  security.pam.services.hyprlock = { };
  security.pam.services.quickshell = { };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "material-you";
    extraPackages = with pkgs; [
      kdePackages.qtsvg
      kdePackages.qtdeclarative
    ];
    settings = {
      General = {
        GreeterEnvironment = "QT_WAYLAND_DISABLE_WINDOWDECORATION=1";
        InputMethod = "";
      };
      Theme = {
        Current = "material-you";
        CursorTheme = "Adwaita";
        CursorSize = 24;
      };
    };
  };

  # Enable zram swap with 100% RAM allocation (zstd compression expands RAM capacity 2-3x)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    priority = 10;
  };

  # Early OOM daemon to prevent system freeze under heavy memory pressure
  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    freeMemThreshold = 10;
    freeSwapThreshold = 10;
  };
  systemd.oomd.enable = false;

  # Sysctl: RAM-first memory policy, zRAM single-page decompression, and IDE mmap capacity
  boot.kernel.sysctl = {
    "vm.swappiness" = 60; # RAM first, zRAM under memory pressure
    "vm.page-cluster" = 0; # Optimize single-page compression/decompression for zRAM
    "vm.max_map_count" = 1048576; # Max mmap limit for JVM, Android Studio, IDEs, and Electron

    # Tối ưu hóa năng lượng: giảm số lần đánh thức CPU & ổ đĩa SSD
    "kernel.nmi_watchdog" = 0; # Tắt ngắt NMI định kỳ để CPU đạt Package C-states sâu
    "vm.dirty_writeback_centisecs" = 1500; # 15s ghi đĩa định kỳ thay vì 5s, để NVMe SSD ở chế độ ngủ (APST)
    "vm.laptop_mode" = 5; # Tối ưu hóa I/O caching khi dùng pin
  };

  services.fstrim.enable = true;

  # Limit systemd journald log size to reduce disk I/O and RAM usage
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    SystemMaxFileSize=20M
    Storage=persistent
  '';

  # Intelligent thermal and power management for Intel CPU
  services.thermald.enable = true;

  # Quyền hạn điều khiển phần cứng không cần root:
  # 1. Sạc nhánh Lenovo (Conservation Mode)
  # 2. Bật/Tắt Intel Turbo Boost (tiết kiệm điện CPU i7-13650HX)
  # 3. Giới hạn xung nhịp tối đa max_perf_pct khi dùng pin
  # 4. Chính sách tiết kiệm điện PCIe ASPM & Runtime PM
  systemd.tmpfiles.rules = [
    "z /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode 0666 root users -"
    "z /sys/devices/system/cpu/intel_pstate/no_turbo 0666 root users -"
    "z /sys/devices/system/cpu/intel_pstate/max_perf_pct 0666 root users -"
    "z /sys/module/pcie_aspm/parameters/policy 0666 root users -"
    "z /sys/bus/pci/devices/*/power/control 0666 root users -"
    "d /var/lib/serpantinum-sddm 0755 dk users -"
    "C /var/lib/serpantinum-sddm/theme.conf 0644 dk users - ${inputs.serpantinum}/config/sddm/themes/material-you/theme.conf"
  ];

  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="platform", DRIVERS=="ideapad_acpi", ATTR{conservation_mode}!="", RUN+="${pkgs.coreutils}/bin/chmod 0666 /sys%p/conservation_mode"
    # Autosuspend cho các thiết bị USB rảnh rỗi (ngoại trừ chuột & bàn phím HID để tránh lag)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{power/control}=="*", ATTR{bInterfaceClass}!="03", ATTR{power/control}="auto"
    # Runtime Power Management cho tất cả thiết bị PCI (Ethernet Realtek, NVMe SSD, WiFi...)
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
  '';

  # Tiết kiệm pin tối đa khi gập máy laptop
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  # ── Audio — PipeWire ───────────────────────────────────────────────────
  services.pipewire = {
    enable = true;

    alsa = {
      enable = true;
      support32Bit = true;
    };

    pulse.enable = true;
    jack.enable = true;
    extraConfig.pipewire."92-audio-performance" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 512;
        "default.clock.max-quantum" = 2048;
      };
    };

    wireplumber = {
      enable = true;
      extraConfig."51-disable-node-suspend" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_input.*"; }
              { "node.name" = "~alsa_output.*"; }
            ];
            actions = {
              update-props = {
                "session.suspend-timeout-seconds" = 5;
              };
            };
          }
        ];
      };
      extraConfig."52-alsa-auto-switch" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "device.name" = "~alsa_card.*"; }
            ];
            actions = {
              update-props = {
                "api.acp.auto-profile" = true;
                "api.acp.auto-port" = true;
              };
            };
          }
        ];
      };
    };
  };

  services.pulseaudio.enable = false;

  security.rtkit.enable = true;

  # ── Bluetooth ──────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };
  services.blueman.enable = true;

  # ── Virtualisation ─────────────────────────────────────────────────────
  virtualisation.docker.enable = true;

  # ── User Account ───────────────────────────────────────────────────────
  users.users.dk = {
    isNormalUser = true;
    description = "duy khanh";

    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "kvm"
      "docker"
    ];

    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # ── Fonts ──────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    material-symbols
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    font-awesome
    sddmSerpantinumTheme
  ];

  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" ];
    serif = [ "Noto Serif" ];
    monospace = [
      "JetBrainsMono Nerd Font Mono"
      "Noto Sans Mono"
    ];
    emoji = [ "Noto Color Emoji" ];
  };

  # ── System Packages ────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    pciutils
    libimobiledevice
    libnotify
    iw
    adwaita-icon-theme
    sddmSerpantinumTheme
    xwayland-satellite
    hyprlock
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # ── Automatic Nix Garbage Collection ───────────────────────────────────
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # ── Nix Settings ───────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    max-jobs = "auto";
    auto-optimise-store = true;
    extra-substituters = [ "https://niri.cachix.org" ];
    extra-trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
  };
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];

  boot.kernelModules = [ "v4l2loopback" ];

  # Ensure extra v4l2loopback clone devices (/dev/video3, /dev/video4) exist with clean labels
  systemd.services.v4l2loopback-extra-devices = {
    description = "Ensure extra Iriun Webcam v4l2loopback devices exist";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ctl="${config.boot.kernelPackages.v4l2loopback.bin}/bin/v4l2loopback-ctl"
      if [ -f /sys/devices/virtual/video4linux/video3/name ] && grep -q '"' /sys/devices/virtual/video4linux/video3/name; then
        "$ctl" delete /dev/video3 || true
      fi
      if [ -f /sys/devices/virtual/video4linux/video4/name ] && grep -q '"' /sys/devices/virtual/video4linux/video4/name; then
        "$ctl" delete /dev/video4 || true
      fi
      if [ ! -e /dev/video3 ]; then
        "$ctl" add -n "Iriun Cam 2" -x 1 /dev/video3 || true
      fi
      if [ ! -e /dev/video4 ]; then
        "$ctl" add -n "Iriun Cam 3" -x 1 /dev/video4 || true
      fi
    '';
  };

  system.stateVersion = "25.11";
}
