{ username, inputs, ... }: {
  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;
    package = inputs.homebrew-brew;
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
      "android-studio"
      "scribus"
      "localsend"
      "vlc"
      "signal"
      "telegram"
      "steam"
      "keyclu"
      "blender"
      "excalidrawz"
      "obs"
      "visual-studio-code"
      "karabiner-elements"
    ];

    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
