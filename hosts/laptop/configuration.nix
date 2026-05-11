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
  networking.hostName = "your-laptop";
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
        qt6Packages.fcitx5-qt
      ];
    };
  };

  # ── NVIDIA Driver ──────────────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.production;

    open = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    powerManagement.enable = false;
    powerManagement.finegrained = false;
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

  security.polkit.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
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

  # Stylix system-level config
  # Phần này sync với stylix config trong home.nix
  stylix = {
    enable = true;
    # Trỏ đến cùng wallpaper với home.nix
    image  = /etc/nixos/home/modules/theme/b-030.jpg;
    # Stylix sẽ tự generate base16 colorscheme từ wallpaper
  };

  system.stateVersion = "25.11";
}
