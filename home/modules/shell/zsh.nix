_:
{
  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ls  = "eza --icons";
        ll  = "eza -la --icons --git";
        lt  = "eza --tree --icons -L 2";
        cat = "bat";
        cd  = "z";

        # Monitor refresh rate (Tiết kiệm pin / Hiệu năng)
        hz60      = "niri msg output eDP-1 mode 1920x1080@60.001";
        hz144     = "niri msg output eDP-1 mode 1920x1080@144.003";
        hz-status = "niri msg outputs";

        # Android emulator launcher
        runadr = "emulator -avd test -gpu host";

        rebuild     = "sudo nixos-rebuild switch --flake /etc/nixos#HiMeo";
        update      = "sudo nix flake update /etc/nixos";
        gc          = "sudo nix-collect-garbage -d";
        sync-config = "cd /etc/nixos && sudo git pull && rebuild";

        g   = "git";
        gst = "git status";
        gaa = "git add .";
        gcm = "git commit -m";
        gp  = "git push";
        gl  = "git log --oneline --graph --decorate";
      };

      initExtra = ''
        # Tự động chuyển đổi hoặc set tần số quét màn hình
        hz() {
          case "$1" in
            60)
              niri msg output eDP-1 mode 1920x1080@60.001 && echo "Display set to 60Hz (tiết kiệm pin)"
              ;;
            144)
              niri msg output eDP-1 mode 1920x1080@144.003 && echo "Display set to 144Hz (mượt mà)"
              ;;
            "")
              if niri msg outputs | grep -q '144.*(current)'; then
                niri msg output eDP-1 mode 1920x1080@60.001 && echo "Chuyển sang 60Hz (tiết kiệm pin)"
              else
                niri msg output eDP-1 mode 1920x1080@144.003 && echo "Chuyển sang 144Hz (mượt mà)"
              fi
              ;;
            *)
              echo "Cách dùng: hz [60|144] (hoặc gõ 'hz' không tham số để tự động toggle)"
              ;;
          esac
        }
      '';
    };
  };
}
