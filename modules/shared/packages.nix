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

    nixd # nix language server
  ];
}
