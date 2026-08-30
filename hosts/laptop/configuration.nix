{
  config,
  pkgs,
  lib,
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
  '';

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  programs.nix-ld.enable = true;

  # Direct monitor capture uses gsr-kms-server.
  programs.gpu-screen-recorder.enable = true;

  # ── Network ────────────────────────────────────────────────────────────
  networking.hostName = "HiMeo";
  networking.networkmanager.enable = true;

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

    # 2. Power management (required on Wayland for sleep/resume stability).
    powerManagement.enable = true;
    powerManagement.finegrained = false;

    prime = {
      # 3. Reverse Prime Sync Mode (renders via NVIDIA for high refresh rates).
      sync.enable = true;

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  services.power-profiles-daemon.enable = true;
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

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sugar-dark";
    settings = {
      Theme = {
        Current = "sugar-dark";
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
        Enable = "Source,Sink,Media,Socket";
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
    sddm-sugar-dark
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

  system.stateVersion = "25.11";
}
