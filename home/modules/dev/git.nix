{ pkgs, ... }:

{
  home.packages = with pkgs; [
    delta
  ];

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "dkhanh264";
        email = "24638601.khanh@student.iuh.edu.vn";
      };

      init.defaultBranch = "main";

      pull.rebase = false;

      push.autoSetupRemote = true;

      alias = {
        lg = "log --oneline --graph --decorate --all";
        st = "status -s";
      };
    };
  };

  programs.delta = {
    enable = true;

    enableGitIntegration = true;

    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
      dark = true;
    };
  };
}
