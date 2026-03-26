{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git
    lazygit
    jq
    fd
    wireguard-tools
    ripgrep
    gh
    bat
    glow
    nmap # provides ncat for Godot LSP connection

  ];
}
