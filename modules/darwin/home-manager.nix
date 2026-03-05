{ username, ... }: {
  users.users.${username}.home = "/Users/${username}";

  home-manager.users.${username} = { pkgs, ... }: {
    home.homeDirectory = "/Users/${username}";

    home.packages = with pkgs; [
      claude-code
    ];

    programs.zsh.shellAliases = {
      rebuild = "sudo darwin-rebuild switch --flake ~/projects/nix-config; source ~/.zshrc";
    };
  };
}
