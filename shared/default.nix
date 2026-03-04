{ pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    git
    lazygit
    jq
  ];
}
