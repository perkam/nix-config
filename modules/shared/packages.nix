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

    nixd # nix language server
  ];
}
