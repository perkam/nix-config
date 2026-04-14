{
  description = "Kacper's Nix configuration for macOS and NixOS";

  inputs = {
    # Darwin (macOS) packages - stable
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

    # NixOS packages - stable (for future Linux machines)
    nixpkgs-nixos.url = "github:NixOS/nixpkgs/nixos-25.05";

    # Unstable packages (for cutting-edge tools like atuin)
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # nix-darwin for macOS system configuration
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Home-manager for user environment
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Homebrew integration for macOS casks
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Secrets management (for future use)
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { ... }@inputs:
    let
      lib = import ./lib { inherit inputs; };
    in
    {
      darwinConfigurations = {
        # Key must match actual hostname for `darwin-rebuild switch --flake .` to work
        "kacpers-MacBook-Pro" = lib.mkDarwinHost {
          hostname = "kacpers-MacBook-Pro";
          hostDir = "macbook-pro"; # Directory in hosts/darwin/
          username = "kacper";
          email = "corgodev@gmail.com";
          gitName = "kacper";
          atuinServer = "https://atuin.homelab.corgo.dev";
          system = "aarch64-darwin";
          profile = "workstation";
        };

        # Future hosts:
        # "mac-mini-server" = lib.mkDarwinHost {
        #   hostname = "mac-mini-server";
        #   username = "admin";
        #   email = "admin@example.com";
        #   profile = "server";
        # };
      };

      nixosConfigurations = {
        # Future hosts:
        # "homelab" = lib.mkNixosHost {
        #   hostname = "homelab";
        #   username = "kacper";
        #   email = "corgodev@gmail.com";
        #   atuinServer = "https://atuin.homelab.corgo.dev";
        #   profile = "server";
        # };
        #
        # "linux-workstation" = lib.mkNixosHost {
        #   hostname = "linux-workstation";
        #   username = "kacper";
        #   email = "corgodev@gmail.com";
        #   system = "x86_64-linux";
        #   profile = "workstation";
        # };
      };
    };
}
