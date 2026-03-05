{ username, ... }: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${username} = { ... }: {
      home.username = username;
      home.stateVersion = "25.05";

      programs.zsh = {
        enable = true;

        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        history = {
          size = 10000;
          ignoreDups = true;
          share = true;
        };

        shellAliases = {
          find = "fd";
        };

        initExtra = ''
          export EDITOR="nvim"
          export LANG="en_US.UTF-8"
        '';

        oh-my-zsh = {
          enable = true;
          theme = "robbyrussell";
        };
      };

      programs.git = {
        enable = true;
        userName = username;
        userEmail = "corgodev@gmail.com";

        extraConfig = {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
          core.autocrlf = "input";
        };

        delta.enable = true;
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  };
}
