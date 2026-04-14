# NixOS-specific shell configuration
# Imported by all NixOS machines
{ flakeDir, ... }:
{
  programs.zsh.shellAliases = {
    update = "sudo nix flake update --flake ${flakeDir}";
    rebuild = "sudo nixos-rebuild switch --flake ${flakeDir}; source ~/.zshrc";
  };
}
