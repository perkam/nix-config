# Workstation profile - development machines with full LSP, GUI tools, etc.
# Extends base profile with dev packages and full neovim
{ pkgs, username, ... }: {
  imports = [ ./base.nix ];

  # Dev tools for workstations
  environment.systemPackages = with pkgs; [
    lazygit
    gh
    claude-code
    imagemagick
    nmap # provides ncat for Godot LSP connection
    uv
  ];

  # Extend home-manager config for workstations
  home-manager.users.${username} = { pkgs, ... }: {
    imports = [ ../modules/home/neovim ];

    # Workstation-specific packages
    home.packages = with pkgs; [ scrcpy ];

    # OpenCode AI assistant
    programs.opencode = {
      enable = true;
      settings = { plugin = [ "opencode-gemini-auth@latest" ]; };
    };
  };
}
