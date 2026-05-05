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
      "nikitabobko/tap/aerospace"
      "whatsapp"
      "krita"
      "notion"
      "android-platform-tools"
      "scribus"
      "localsend"
      "vlc"
      "signal"
      "telegram"
      "steam"
      "keyclu"
    ];

    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
