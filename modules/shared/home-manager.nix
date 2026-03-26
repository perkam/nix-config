{ username, ... }: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${username} = { pkgs, ... }: {
      imports = [ ./neovim.nix ];

      home.username = username;
      home.stateVersion = "25.05";

      home.packages = with pkgs; [ scrcpy ];

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
          cat = "smart_cat";
          nix-config =
            "cwd=$(pwd) && cd ~/projects/nix-config/ && nvim && cd \${cwd}";
        };

        initExtra = ''
          export LANG="en_US.UTF-8"

          ask() {
            opencode -m "anthropic/claude-haiku-4-5" run "$*" | glow
          }
          smart_cat() {
            if [[ $1 == *.md ]]; then
              PAGER='bat' glow -p "$1"
            else
              bat "$1"
            fi
          }
        '';

        oh-my-zsh = {
          enable = true;
          theme = "robbyrussell";
        };
      };

      programs.git = {
        enable = true;
        settings = {
          user.name = username;
          user.email = "corgodev@gmail.com";
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
          core.autocrlf = "input";
        };
      };

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
      };

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
  };
}
