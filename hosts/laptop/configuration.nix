{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ── Bootloader ─────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];
  

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
    ];
  };

  # ── Wayland & Hyprland ─────────────────────────────────────────────────
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  
  programs.steam = {
  enable = true;
  };	

  security.polkit.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
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
  };

  services.pulseaudio.enable = false;

  security.rtkit.enable = true;

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
