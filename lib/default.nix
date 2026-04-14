{ inputs }:

let
  # Helper to create Darwin (macOS) hosts
  mkDarwinHost =
    {
      hostname,
      username,
      system ? "aarch64-darwin",
      profile ? "workstation",
      hostDir ? null, # Directory name in hosts/darwin/, defaults to hostname
      # User configuration - pass explicitly per host
      email,
      gitName ? username,
      flakeDir ? "~/projects/nix-config",
      atuinServer ? null,
    }:
    let
      hostPath = if hostDir != null then hostDir else hostname;
      overlays = import ../overlays { inherit inputs; };
      pkgs = import inputs.nixpkgs {
        inherit system overlays;
      };
      pkgs-unstable = import inputs.nixpkgs-unstable { inherit system; };

      # Common specialArgs passed to all modules
      specialArgs = {
        inherit
          username
          hostname
          pkgs-unstable
          inputs
          email
          gitName
          flakeDir
          atuinServer
          ;
      };

      # Profile to import based on the profile argument
      profileModule =
        {
          workstation = ../profiles/workstation.nix;
          server = ../profiles/server.nix;
          base = ../profiles/base.nix;
        }
        .${profile};

      # Darwin-specific home-manager config (shell aliases, etc.)
      darwinHomeModule = {
        home-manager.users.${username} = {
          imports = [ ../modules/home/shell/darwin.nix ];
          _module.args = { inherit flakeDir; };
        };
      };
    in
    inputs.nix-darwin.lib.darwinSystem {
      inherit system specialArgs;
      modules = [
        { nixpkgs.overlays = overlays; }
        profileModule
        darwinHomeModule
        ../hosts/darwin/${hostPath}
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.home-manager.darwinModules.home-manager
      ];
    };

  # Helper to create NixOS hosts (for future use)
  mkNixosHost =
    {
      hostname,
      username,
      system ? "x86_64-linux",
      profile ? "server",
      hostDir ? null, # Directory name in hosts/nixos/, defaults to hostname
      # User configuration - pass explicitly per host
      email,
      gitName ? username,
      flakeDir ? "~/projects/nix-config",
      atuinServer ? null,
    }:
    let
      hostPath = if hostDir != null then hostDir else hostname;
      overlays = import ../overlays { inherit inputs; };
      pkgs = import inputs.nixpkgs-nixos {
        inherit system overlays;
      };
      pkgs-unstable = import inputs.nixpkgs-unstable { inherit system; };

      specialArgs = {
        inherit
          username
          hostname
          pkgs-unstable
          inputs
          email
          gitName
          flakeDir
          atuinServer
          ;
      };

      profileModule =
        {
          workstation = ../profiles/workstation.nix;
          server = ../profiles/server.nix;
          base = ../profiles/base.nix;
        }
        .${profile};

      # NixOS-specific home-manager config (shell aliases, etc.)
      nixosHomeModule = {
        home-manager.users.${username} = {
          imports = [ ../modules/home/shell/nixos.nix ];
          _module.args = { inherit flakeDir; };
        };
      };
    in
    inputs.nixpkgs-nixos.lib.nixosSystem {
      inherit system specialArgs;
      modules = [
        profileModule
        nixosHomeModule
        ../hosts/nixos/${hostPath}
        inputs.home-manager.nixosModules.home-manager
      ];
    };

in
{
  inherit mkDarwinHost mkNixosHost;
}
