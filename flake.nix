{
  description = "MacOS nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nix-darwin, nix-homebrew, home-manager, ... }: {
    darwinConfigurations."kacpers-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [ 
        ./hosts/darwin/default.nix
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
      ];
      specialArgs = {
        username = "kacper";
        hostname = "kacpers-MacBook-Pro";
      };
    };
  };
}
