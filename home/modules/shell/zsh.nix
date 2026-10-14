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

        # Monitor refresh rate & Siêu tiết kiệm pin (ECO Mode)
        hz        = "eco";
        hz60      = "eco 60";
        hz144     = "eco 144";
        hz-status = "eco status";
        eco       = "eco";
        bypass    = "eco bypass";
        bp        = "eco bypass";
        powersave = "eco on";
        tietkiem  = "eco on";
        pin       = "eco status";
        cap       = "eco cap";

        # Monitor rotation (Màn hình rời HDMI-A-1)
        rot90     = "niri msg output HDMI-A-1 transform 90";
        rot0      = "niri msg output HDMI-A-1 transform normal";
        rotnormal = "niri msg output HDMI-A-1 transform normal";
        rot       = "rotate-ext";
        xoay      = "rotate-ext";

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

      initContent = ''
        export PATH="$HOME/.local/bin:$PATH"

        # eco / hz command wrapper
        hz() {
          if command -v eco >/dev/null 2>&1; then
            eco "$@"
          elif [[ -x "$HOME/.local/bin/eco" ]]; then
            "$HOME/.local/bin/eco" "$@"
          else
            echo "Lỗi: Không tìm thấy lệnh eco"
            return 1
          fi
        }

        # Xoay màn hình rời (HDMI-A-1) hoặc tự động toggle giữa ngang và dọc
        rotate-ext() {
          case "$1" in
            90)
              niri msg output HDMI-A-1 transform 90 && echo "Màn hình rời (HDMI-A-1): 90° (xoay dọc ngược chiều kim đồng hồ)"
              ;;
            0|normal)
              niri msg output HDMI-A-1 transform normal && echo "Màn hình rời (HDMI-A-1): Bình thường (ngang)"
              ;;
            270)
              niri msg output HDMI-A-1 transform 270 && echo "Màn hình rời (HDMI-A-1): 270° (xoay dọc theo chiều kim đồng hồ)"
              ;;
            180)
              niri msg output HDMI-A-1 transform 180 && echo "Màn hình rời (HDMI-A-1): 180°"
              ;;
            "")
              if niri msg outputs | grep -A 10 'HDMI-A-1' | grep -q 'Transform: normal'; then
                niri msg output HDMI-A-1 transform 90 && echo "Chuyển màn hình rời sang: Dọc (90° ngược chiều kim đồng hồ)"
              else
                niri msg output HDMI-A-1 transform normal && echo "Chuyển màn hình rời sang: Ngang (bình thường)"
              fi
              ;;
            *)
              echo "Cách dùng: rot [90|0|normal|270] (hoặc gõ 'rot' / 'xoay' không tham số để tự động toggle ngang/dọc)"
              ;;
          esac
        }
      '';
    };
  };
}
