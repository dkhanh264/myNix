{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ── Bootloader ─────────────────────────────────────────────────────────
  boot.loader.efi.canTouchEfiVariables = true;

  # Firewall configuration for LocalSend & custom ports
  networking.firewall.allowedUDPPorts = [
    4698
    53317 # LocalSend Multicast / UDP Discovery
  ];
  networking.firewall.allowedTCPPorts = [
    53317 # LocalSend TCP File Transfer
  ];


  boot.kernelParams = [
    "pcie_aspm=force"
    "nowatchdog"
    "nmi_watchdog=0"
  ];

  # Improve headset/external mic detection on many HDA laptops.
  boot.extraModprobeConfig = ''
    options snd_hda_intel dmic_detect=0
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

  # ── Bộ gõ Tiếng Việt Lotus (Fcitx5 Lotus) ────────────────────────────────
  services.fcitx5-lotus = {
    enable = true;
    users = [ "dk" ];
  };
  #---Android SDK----------------------------------------------------------
  nixpkgs.config.android_sdk.accept_license = true;
  # ── NVIDIA Driver ──────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    
    # 1. Chuyển sang driver độc quyền (proprietary). Driver open-source hiện tại vẫn chưa hoàn toàn ổn định cho multi-monitor Wayland.
    open = false; 

    # 2. Bật powerManagement (Bắt buộc trên Wayland để tránh lỗi crash/giật lag khi sleep/resume).
    powerManagement.enable = true; 
    powerManagement.finegrained = false;

    prime = {
      # 3. Đổi sang chế độ Sync Mode (Reverse Prime). 
      # Chế độ này sẽ dùng GPU NVIDIA để render toàn bộ, giúp màn hình rời hoạt động ở mức FPS tối đa và mượt mà nhất.
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
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
      niri = {
        default = lib.mkForce [ "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      };
    };
  };

  security.polkit.enable = true;
  security.pam.services.hyprlock = {};

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

  # enable zram swap with 100% RAM allocation (zstd compression expands RAM capacity 2-3x)
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
    freeMemThreshold = 5;
    freeSwapThreshold = 5;
  };
  systemd.oomd.enable = false;

  # 2. Tối ưu Kernel Sysctl giúp hệ thống phản hồi cực nhanh & tận dụng zRAM
  boot.kernel.sysctl = {
     "vm.swappiness" = 160;          # Ưu tiên nén RAM zRAM trước khi đĩa cứng
     "vm.watermark_boost_factor" = 0; # Giảm bớt tải thu hồi trang rảnh rỗi không cần thiết
     "vm.watermark_scale_factor" = 125;
     "vm.page-cluster" = 0;          # Tối ưu hóa nén/giải nén đơn trang zRAM
     "vm.vfs_cache_pressure" = 125;  # Thu hồi cache dentry & inode giải phóng RAM khi cần
     "vm.dirty_ratio" = 10;          # Giới hạn dirty memory tối đa 10% RAM
     "vm.dirty_background_ratio" = 5; # Xả dirty cache xuống đĩa sớm khi đạt 5% RAM
     "vm.max_map_count" = 1048576;   # Tăng giới hạn mmap cho IDE/JVM/Electron
  };

  services.fstrim.enable = true;

  # Giới hạn dung lượng lưu log của systemd journald để giảm bớt ghi đĩa (I/O) và tiết kiệm RAM
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    SystemMaxFileSize=20M
    Storage=persistent
  '';

  # Quản lý nhiệt độ & điện năng thông minh cho CPU Intel
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
    monospace = [ "JetBrainsMono Nerd Font Mono" "Noto Sans Mono" ];
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

  # ── Automatic Nix Garbage Collection ───────────────────────────────
  nix.gc = {
    automatic = true;
    dates = "weekly";           # Chạy mỗi tuần (hoặc daily)
    options = "--delete-older-than 14d";
  };

  # ── Nix Settings ───────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
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
