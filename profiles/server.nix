# Server profile - minimal server config without GUI or heavy dev tools
# Extends base profile with minimal neovim (no LSP/formatters)
{ username, ... }:
{
  imports = [ ./base.nix ];

  # Extend home-manager config for servers
  home-manager.users.${username} =
    { ... }:
    {
      imports = [
        ../modules/home/neovim/minimal.nix
      ];
    };
}
