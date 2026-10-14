{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

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
    options v4l2loopback devices=1 video_nr=2 card_label="Iriun Webcam" exclusive_caps=1

    # Tối ưu hóa tiết kiệm pin cho WiFi & Audio
    options iwlwifi power_save=1
    options iwlmvm power_scheme=3
    options snd_hda_intel power_save=1 power_save_controller=Y
    options snd_soc_sof power_save=1
  '';

  boot.kernelParams = [
    "pcie_aspm=force"
    "nvme_core.default_ps_max_latency_us=0" # Cho phép NVMe SSD vào trạng thái tiết kiệm điện sâu nhất (APST)
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
      # Khi cần game/đồ họa nặng (Steam, DaVinci), chỉ cần chạy qua lệnh: nvidia-offload <app>
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

  # ── Steam & Gaming ─────────────────────────────────────────────────────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
    protontricks.enable = true;
    extest.enable = true;
  };

  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

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
  security.pam.services.hyprlock = { };
  security.pam.services.quickshell = { };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "material-you";
    extraPackages = with pkgs; [
      kdePackages.qt5compat
      kdePackages.qtsvg
      kdePackages.qtdeclarative
    ];
    settings = {
      Theme = {
        Current = "material-you";
        CursorTheme = "Adwaita";
        CursorSize = 24;
        Font = "Noto Sans";
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
  systemd.tmpfiles.rules = [
    "z /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode 0666 root users -"
    "z /sys/devices/system/cpu/intel_pstate/no_turbo 0666 root users -"
  ];

  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="platform", DRIVERS=="ideapad_acpi", ATTR{conservation_mode}!="", RUN+="${pkgs.coreutils}/bin/chmod 0666 /sys%p/conservation_mode"
    # Autosuspend cho các thiết bị USB rảnh rỗi (ngoại trừ chuột & bàn phím HID để tránh lag)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{power/control}=="*", ATTR{bInterfaceClass}!="03", ATTR{power/control}="auto"
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
    (pkgs.stdenv.mkDerivation {
      pname = "sddm-serpantinum-theme";
      version = "1.0";
      src = "${inputs.serpantinum}/config/sddm/themes";
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/share/sddm/themes
        cp -r material-you $out/share/sddm/themes/
      '';
    })
    xwayland-satellite
    hyprlock
    mangohud
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

  system.stateVersion = "25.11";
}
