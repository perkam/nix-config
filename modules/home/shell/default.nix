# Core zsh configuration - cross-platform
{ lib, ... }: {
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      ignoreDups = true;
      share = true;
    };

    # Cross-platform aliases
    shellAliases = {
      find = "fd";
      cat = "smart_cat";
      nix-config =
        "cwd=$(pwd) && cd ~/projects/nix-config/ && nvim && cd \${cwd}";
      cd = "z";
    };

    initContent = ''
      export LANG="en_US.UTF-8"

      ask() {
        claude -c -p "$*" | glow
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
}
