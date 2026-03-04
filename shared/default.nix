{ pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    lazygit
    jq
    fd
    wireguard-tools
    neovim

    nixd # nix language server
  ];
}
