{ username, ... }: {
  home-manager.users.${username} = {
    home.file.".aerospace.toml" = {
      source = ./aerospace/aerospace.toml;
    };
  };
}
