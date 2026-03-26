{ username, ... }: {
  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;

    casks = [
      "ghostty"
      "firefox"
      "google-chrome"
      "bitwarden"
      "slack"
      "spotify"
      "obsidian"
      "godot-mono"
      "dotnet-sdk" # Required by godot-mono
      "libreoffice"
      "phoenix"
      "karabiner-elements"
      "alfred" # Required for phoenix space switcher
      "whatsapp"
      "krita"
      "notion"
      "android-platform-tools"
    ];

    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
