{ username, ... }: {
  users.users.${username}.home = "/Users/${username}";

  home-manager.users.${username} = { ... }: {
    home.homeDirectory = "/Users/${username}";

    programs.zsh.shellAliases = {
      rebuild = "sudo darwin-rebuild switch --flake ~/projects/nix-config; source ~/.zshrc";
    };
  };
}
