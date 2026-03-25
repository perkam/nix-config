{ username, ... }: {
  users.users.${username}.home = "/Users/${username}";

  home-manager.users.${username} = { pkgs, ... }: {
    home.homeDirectory = "/Users/${username}";

    programs.opencode = {
      enable = true;
      settings = { plugin = [ "opencode-gemini-auth@latest" ]; };
    };

    programs.zsh.shellAliases = {
      update = "sudo nix flake update --flake ~/projects/nix-config";
      rebuild =
        "sudo darwin-rebuild switch --flake ~/projects/nix-config; source ~/.zshrc";
    };
  };
}
