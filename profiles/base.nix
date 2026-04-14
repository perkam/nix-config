# Base profile - minimal config for ALL machines (macOS and NixOS)
# Contains core CLI tools and cross-platform home-manager config
{
  pkgs,
  username,
  pkgs-unstable,
  email,
  gitName,
  atuinServer,
  ...
}:
{
  # Core CLI tools needed everywhere
  environment.systemPackages = with pkgs; [
    jq
    fd
    ripgrep
    bat
    glow
    wireguard-tools
  ];

  # Home-manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    # Pass specialArgs to home-manager modules
    extraSpecialArgs = {
      inherit
        username
        email
        gitName
        atuinServer
        pkgs-unstable
        ;
    };

    users.${username} =
      { ... }:
      {
        imports = [
          ../modules/home/shell
          ../modules/home/git.nix
          ../modules/home/tools.nix
        ];

        home.username = username;
        home.stateVersion = "25.05";
      };
  };
}
