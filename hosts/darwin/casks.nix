{ pkgs, ... }: {
  nix-homebrew = {
    enable = true;
    user = "kacper";
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    
    casks = [
      "ghostty"
      "firefox"
      "bitwarden"
      "slack"
      "spotify"
    ];
   
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  }; 
}
