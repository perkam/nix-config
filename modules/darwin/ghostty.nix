{ username, ... }: {
  home-manager.users.${username} = {
    home.file.".config/ghostty/config" = {
      text = ''
        theme = Catppuccin Macchiato
        keybind = cmd+t=new_window
      '';
    };
  };
}
