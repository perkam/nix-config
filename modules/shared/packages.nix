{ pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    lazygit
    jq
    fd
    wireguard-tools
    neovim
    lunarvim
    ripgrep
    gh
    bat
    glow

    nixd # nix language server
  ];
}
