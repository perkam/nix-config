{ username, ... }: {
  imports = [
    ../../modules/darwin/system.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/shared/packages.nix
    ../../modules/darwin/home-manager.nix
    ../../modules/shared/home-manager.nix
  ];
  
  # Global settings
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
  system.primaryUser = username;
}

