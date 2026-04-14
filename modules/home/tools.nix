# Development tools - direnv, zoxide, atuin
{ lib, pkgs, pkgs-unstable, atuinServer, ... }: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    package = pkgs-unstable.atuin;
    settings = {
      search_mode = "fuzzy";
      filter_mode = "global";
    } // lib.optionalAttrs (atuinServer != null) {
      sync_address = atuinServer;
      sync_frequency = "5m";
    };
  };
}
