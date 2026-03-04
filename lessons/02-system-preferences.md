# Lesson 2: System Preferences

> **Goal**: Use nix-darwin to declaratively manage macOS system settings — keyboard, trackpad, Dock, Finder, and dark mode. After this lesson, you'll never touch System Settings for these options again.

## Prerequisites

- Lesson 1 complete — `darwin-rebuild switch` works
- You have a working `flake.nix` and `hosts/darwin/default.nix`

## Concepts

### system.defaults — Your macOS Preferences Pane in Code

macOS stores preferences in plist files (like the Windows registry). Normally you change them through System Settings or `defaults write` commands. nix-darwin exposes them as structured Nix options under `system.defaults`.

```
Ansible analogy:
  community.general.osx_defaults:
    domain: NSGlobalDomain         →  system.defaults.NSGlobalDomain
    key: AppleShowAllExtensions    →  system.defaults.NSGlobalDomain.AppleShowAllExtensions
    value: true                    →  = true;
```

### How Nix Options Work

Every nix-darwin option has:
- A **type** (bool, int, string, list, etc.)
- A **default** value
- A **description**

You can browse all options at: https://daiderd.com/nix-darwin/manual/index.html

The pattern is always: `category.subcategory.option = value;`

### The Module Pattern

Your `default.nix` is a **module** — a function that returns an attribute set of configuration. Modules get merged together, so you can split settings across files. For now, we'll keep everything in one file.

```nix
# A module is just:
{ pkgs, ... }:   # function arguments (pkgs + anything else)
{
  # attribute set of configuration
  some.option = "value";
}
```

## Exercises

### Exercise 1: Keyboard Settings

Add these to your `hosts/darwin/default.nix`. Look up the exact option names yourself — use the nix-darwin manual or run `darwin-rebuild options | grep -i keyboard`.

```nix
# In hosts/darwin/default.nix, add:

# 1. Set key repeat rate to fast (2 = fast)
#    Hint: system.defaults.NSGlobalDomain.KeyRepeat = ___

# 2. Set delay before key repeat starts (15 = short)
#    Hint: system.defaults.NSGlobalDomain.InitialKeyRepeat = ___

# 3. Disable auto-correct
#    Hint: system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = ___

# 4. Disable auto-capitalization
#    Hint: system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = ___
```

### Exercise 2: Trackpad

```nix
# 5. Enable tap to click
#    Hint: system.defaults.trackpad.Clicking = ___
#    Also: system.defaults.NSGlobalDomain."com.apple.mouse.tapBehavior" = 1;

# 6. Enable three-finger drag
#    Hint: system.defaults.trackpad.TrackpadThreeFingerDrag = ___
```

### Exercise 3: Dock

```nix
# 7. Auto-hide the Dock
#    Hint: system.defaults.dock.autohide = ___

# 8. Set icon size (48 is reasonable)
#    Hint: system.defaults.dock.tilesize = ___

# 9. Don't show recent apps in Dock
#    Hint: system.defaults.dock.show-recents = ___

# 10. Minimize windows using "scale" effect (instead of genie)
#     Hint: system.defaults.dock.mineffect = "___";
```

### Exercise 4: Finder & Global

```nix
# 11. Show file extensions in Finder
#     Hint: system.defaults.NSGlobalDomain.AppleShowAllExtensions = ___

# 12. Show path bar in Finder
#     Hint: system.defaults.finder.ShowPathbar = ___

# 13. Default to list view in Finder
#     Hint: system.defaults.finder.FXPreferredViewStyle = "___";
#     Values: "Nlsv" (list), "icnv" (icons), "clmv" (columns), "Flwv" (gallery)

# 14. Use dark mode
#     Hint: system.defaults.NSGlobalDomain.AppleInterfaceStyle = "___";
```

### Exercise 5: Touch ID for sudo

This is a nix-darwin option outside of `system.defaults`:

```nix
# 15. Enable Touch ID for sudo authentication
#     Hint: security.pam.services.sudo_local.touchIdAuth = ___
```

### Exercise 6: Build and apply

```bash
cd /Users/kacper/projects/nix-config
git add -A
darwin-rebuild switch --flake .
```

Some settings need a logout/restart to take effect. The Dock changes should be visible immediately.

## Verification

```bash
# Check that your settings applied:
defaults read NSGlobalDomain KeyRepeat
# Should output: 2

defaults read NSGlobalDomain AppleInterfaceStyle
# Should output: Dark

defaults read com.apple.dock autohide
# Should output: 1

# Check your generation count increased
darwin-rebuild --list-generations
```

## Comprehension Questions

1. **What's the difference between `system.defaults.NSGlobalDomain` and `system.defaults.dock`?** Why are some settings under NSGlobalDomain?

2. **What happens if you remove a setting** from your config and rebuild? Does it revert to default, or stay at the value you set? (Try it — remove one setting, rebuild, and check with `defaults read`.)

3. **In Ansible terms**, is `darwin-rebuild switch` idempotent? What happens if you run it twice with no changes?

4. **You now have generation 2.** How would you roll back to generation 1 if you hate the trackpad settings? What command would you use?

5. **Why `security.pam.services.sudo_local.touchIdAuth`** and not `system.defaults.something`? What does this tell you about nix-darwin's scope — does it only manage macOS preferences?
