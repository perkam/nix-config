# Darwin-specific shell configuration
# Imported by all macOS machines
{ flakeDir, ... }: {
  programs.zsh.shellAliases = {
    update = "sudo nix flake update --flake ${flakeDir}";
    rebuild = "sudo darwin-rebuild switch --flake ${flakeDir}; source ~/.zshrc";
    add-cask = "vim '${flakeDir}/modules/darwin/homebrew.nix'";
  };
}
