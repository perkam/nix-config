# Machine-specific configuration for Kacper's MacBook Pro
{ username, ... }:
{
  imports = [
    ../../../modules/darwin/system.nix
    ../../../modules/darwin/homebrew.nix
    ../../../modules/darwin/phoenix.nix
    ../../../modules/darwin/apps/open-in-neovim.nix
    ../../../modules/darwin/login-items.nix
  ];

  # Global settings
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 6;
  system.primaryUser = username;

  # User configuration
  users.users.${username}.home = "/Users/${username}";

  # Machine-specific home-manager config
  home-manager.users.${username} =
    { ... }:
    {
      home.homeDirectory = "/Users/${username}";
    };
}
