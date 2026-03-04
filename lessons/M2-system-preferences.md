# M2: System Preferences — Declarative macOS Settings

> **Goal**: Use nix-darwin to manage macOS system settings declaratively. After this lesson, you'll never touch System Settings for keyboard, trackpad, Dock, and Finder — they'll all be in code.

## Prerequisites

- M1 complete — `darwin-rebuild switch` works
- `hosts/darwin/default.nix` exists and is building

---

## Concepts

### `system.defaults` — macOS Preferences in Code

macOS stores preferences in plist files (like a key-value registry). You normally change them through System Settings or `defaults write` on the command line. nix-darwin exposes them as Nix options under `system.defaults`.

```
Ansible analogy:
  community.general.osx_defaults:
    domain: NSGlobalDomain
    key: KeyRepeat
    value: 2
  →
  system.defaults.NSGlobalDomain.KeyRepeat = 2;
```

The categories map to macOS preference domains:
- `system.defaults.NSGlobalDomain.*` — global system-wide settings
- `system.defaults.dock.*` — Dock settings
- `system.defaults.finder.*` — Finder settings
- `system.defaults.trackpad.*` — trackpad settings

### Browsing Available Options

nix-darwin has a manual with all available options:

```bash
# Build and open the nix-darwin manual
nix build github:nix-darwin/nix-darwin#manualHTML --extra-experimental-features 'nix-command flakes'
open ./result/share/doc/darwin/index.html

# Or search online: https://daiderd.com/nix-darwin/manual/index.html

# Search options from CLI (after darwin-rebuild installs it)
darwin-option system.defaults.dock.autohide
```

---

## Exercises

Add these settings to your `hosts/darwin/default.nix`. Look up the options yourself in the manual for anything marked with a hint.

### Exercise 1: Keyboard

```nix
# In hosts/darwin/default.nix, add these inside the { } return set:

# Fast key repeat
system.defaults.NSGlobalDomain.KeyRepeat = 2;           # 2 = fast (default: 6)
system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;   # 15 = short delay (default: 25)

# Disable autocorrect annoyances
system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = false;
system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
```

### Exercise 2: Trackpad

```nix
# Enable tap to click
system.defaults.trackpad.Clicking = true;
system.defaults.NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;

# Three-finger drag (hint: look up TrackpadThreeFingerDrag)
system.defaults.trackpad.TrackpadThreeFingerDrag = true;
```

### Exercise 3: Dock

```nix
# Auto-hide the Dock
system.defaults.dock.autohide = true;

# Remove delay before Dock appears/disappears
system.defaults.dock.autohide-delay = 0.0;
system.defaults.dock.autohide-time-modifier = 0.2;

# Icon size and appearance
system.defaults.dock.tilesize = 48;
system.defaults.dock.show-recents = false;
system.defaults.dock.mineffect = "scale";    # "genie" or "scale"

# Don't rearrange Spaces based on recent use
system.defaults.dock.mru-spaces = false;
```

### Exercise 4: Finder and Global

```nix
# Show all file extensions
system.defaults.NSGlobalDomain.AppleShowAllExtensions = true;

# Show path bar and status bar in Finder
system.defaults.finder.ShowPathbar = true;
system.defaults.finder.ShowStatusBar = true;

# Default to list view in Finder
# "Nlsv" = list, "icnv" = icons, "clmv" = columns, "Flwv" = gallery
system.defaults.finder.FXPreferredViewStyle = "Nlsv";

# Show full POSIX path in Finder title bar
system.defaults.finder._FXShowPosixPathInTitle = true;

# Dark mode
system.defaults.NSGlobalDomain.AppleInterfaceStyle = "Dark";
```

### Exercise 5: Touch ID for sudo

This is a nix-darwin option outside of `system.defaults`:

```nix
# Enable Touch ID for sudo authentication
security.pam.services.sudo_local.touchIdAuth = true;
```

### Exercise 6: Build and apply

```bash
# Stage your changes (git tracks all files in a flake)
git add -A

darwin-rebuild switch --flake .
```

Some settings require logout/restart to take effect. Dock changes are usually immediate.

---

## Verification

```bash
# Check specific settings applied:
defaults read NSGlobalDomain KeyRepeat
# → 2

defaults read NSGlobalDomain AppleInterfaceStyle
# → Dark

defaults read com.apple.dock autohide
# → 1

# Your generation count should have increased
darwin-rebuild --list-generations
```

---

## Comprehension Questions

1. **What's the difference between `system.defaults.NSGlobalDomain` and `system.defaults.dock`?** Why are some settings under NSGlobalDomain?

2. **What happens if you remove a setting from your config and rebuild?** Does it revert to the macOS default, stay at the value you set, or something else? Test by removing one option, rebuilding, and checking with `defaults read`.

3. **Is `darwin-rebuild switch` idempotent?** Run it twice in a row with no changes. What happens? How does this compare to `ansible-playbook` run twice?

4. **You now have generation 2.** How would you roll back to generation 1 if you hate the Dock settings? What's the command? What happens to generation 2 after you roll back?

5. **Why does `security.pam.services.sudo_local.touchIdAuth` exist under `security.pam`** rather than `system.defaults`? What does this tell you about nix-darwin's scope — does it only manage macOS preferences?
