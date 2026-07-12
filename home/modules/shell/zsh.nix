{ pkgs, ... }:
{
  programs.zsh = {
    enable                    = true;
    autosuggestion.enable     = true;
    enableCompletion          = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls  = "eza --icons";
      ll  = "eza -la --icons --git";
      lt  = "eza --tree --icons -L 2";
      cat = "bat";
      cd  = "z";

      # Khởi động emulator android
      runadr = "emulator -avd test -gpu host";

      # THAY "your-laptop" bằng hostname thực tế
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
      eval "$(zoxide init zsh)"
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh
    '';
  };
}
