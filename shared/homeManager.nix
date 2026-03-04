home-manager = {
  useGlobalPkgs = true;
  useUserPackages = true;

  users.kacper = { pkgs, ... }: {
    home.username = "kacper";
    home.homeDirectory = "/Users/kacper";
    home.stateVersion = "25.11";

    programs.zsh = {
      enable = true;
      
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      history = {
        size = 10000;
        ignoreDups = true;
        share = true;
      }

    shellAliases = {
      find = "fd";
      rebuild = "darwin-rebuild switch --flake ~/projects/nix-config";
    };

    initExtra = ''
      # Custom zsh config that Home Manager doesn't have options for
      export EDITOR="neovim"
      export LANG="en_US.UTF-8"
    '';
    }
  }
}
