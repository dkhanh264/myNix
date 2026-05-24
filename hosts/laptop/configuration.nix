{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ── Bootloader ─────────────────────────────────────────────────────────
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  # Improve headset/external mic detection on many HDA laptops.
  boot.extraModprobeConfig = ''
    options snd_hda_intel dmic_detect=0
  '';

  boot.lanzaboote = {
  enable = true;
  pkiBundle = "/etc/secureboot";
  };

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

  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      intel-media-driver
      libva-vdpau-driver
      libvdpau-va-gl
      vulkan-tools
      vulkan-loader
      mesa
    ];
  };

  # ── Wayland & Hyprland ─────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.steam = {
    enable = true;
    # mở firewall cho remote play
    remotePlay.openFirewall = true;

    # mở firewall cho dedicated server
    dedicatedServer.openFirewall = true;

    # tối ưu cho Wayland/Hyprland
    gamescopeSession.enable = true;
  };	

  security.polkit.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sugar-candy";
    settings = {
      Theme = {
        Current = "sugar-candy";
        CursorTheme = "Adwaita";
        CursorSize = 24;
        Font = "JetBrains Mono Nerd Font";
      };
    };
  };

  # enable zram swap
  zramSwap = {
  enable = true;
  memoryPercent = 100;
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
                "session.suspend-timeout-seconds" = 0;
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

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # ── Bluetooth ──────────────────────────────────────────────────────────
  hardware.bluetooth.enable = true;
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
    ];

    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # ── Fonts ──────────────────────────────────────────────────────────────
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    font-awesome
  ];

  # ── System Packages ────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    pciutils
  ];

  environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
  STEAM_EXTRA_COMPAT_TOOLS_PATHS =
    "/home/dk/.steam/root/compatibilitytools.d";
};

  # ── Nix Settings ───────────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = "auto";
  };
  boot.extraModulePackages = with config.boot.kernelPackages; [
  v4l2loopback
  ];

  boot.kernelModules = [ "v4l2loopback" ];

  system.stateVersion = "25.11";
}
