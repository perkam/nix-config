{ ... }: {
  # Keyboard
  system.defaults.NSGlobalDomain.KeyRepeat = 2; # 2 is fast, 120 is slow
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 15; # same here

  # Disable autocorrect annoyances
  system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = false;

  # Trackpad
  system.defaults.trackpad.Clicking = true; # tap to click
  system.defaults.NSGlobalDomain."com.apple.trackpad.scaling" = 1.5;
  system.defaults.NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;
  system.defaults.trackpad.TrackpadThreeFingerDrag = true; # three-finger drag

  # Dock
  system.defaults.dock.autohide = true;
  system.defaults.dock.autohide-delay = 0.0; # no delay before appearing
  system.defaults.dock.autohide-time-modifier = 0.2; # fast animation
  system.defaults.dock.tilesize = 85; # defaults read com.apple.dock tilesize
  system.defaults.dock.show-recents = false;
  system.defaults.dock.mineffect = "scale"; # "genie" or "scale"
  system.defaults.dock.mru-spaces = false; # don't rearrange Spaces

  # Finder and global
  system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;
  system.defaults.finder.ShowPathbar = true;
  system.defaults.finder.ShowStatusBar = true;
  system.defaults.finder.FXPreferredViewStyle = "Nlsv"; # list view
  system.defaults.finder._FXShowPosixPathInTitle = true; # full path in title
  system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark"; # dark mode

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;
}
