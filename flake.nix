{
  description = "MacOS nix configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    home-manager.url = "github:nix-community/home-manager";
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
