# Minimal neovim configuration for servers
# Basic editor without LSP servers or formatters
{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Minimal tools - just what's needed for basic editing
    extraPackages = with pkgs; [
      ripgrep
      fd
      tree-sitter
    ];
  };

  # Symlink the nvim config directory (uses same config, LSP just won't be available)
  home.file.".config/nvim" = {
    source = ./.;
    recursive = true;
    # Exclude nix files from being copied
    onChange = ''
      rm -f ~/.config/nvim/default.nix ~/.config/nvim/minimal.nix
    '';
  };
}
