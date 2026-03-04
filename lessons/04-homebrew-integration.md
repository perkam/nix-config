# Lesson 4: Homebrew Integration

> **Goal**: Use nix-homebrew to manage macOS GUI apps (casks) declaratively. Learn why Homebrew is still needed alongside Nix and how `follows` keeps inputs in sync.

## Prerequisites

- Lesson 3 complete — CLI packages managed via nixpkgs
- Homebrew installed (`/opt/homebrew/bin/brew` exists) — if not, that's fine, nix-homebrew can bootstrap it

## Concepts

### Why Homebrew When We Have Nix?

Nix can install most CLI tools, but macOS GUI apps (`.app` bundles) are a different story. Many commercial apps (1Password, Slack, browsers) aren't in nixpkgs or don't build cleanly on macOS. Homebrew Casks handle these well.

The solution: use **Nix for CLI tools** and **Homebrew Casks for GUI apps**, but manage Homebrew itself declaratively through Nix.

```
Terraform analogy:
  Nix is like your main Terraform provider
  nix-homebrew is like a secondary provider for resources the main one can't handle
  You declare both in the same config, and they work together
```

### nix-homebrew and `follows`

You already added `nix-homebrew` as a flake input in Lesson 1. It has its own `nixpkgs` input. Without `follows`, it would download a separate copy of nixpkgs — wasting space and potentially causing version conflicts.

```nix
# Without follows: two copies of nixpkgs
inputs.nixpkgs.url = "...";
inputs.nix-homebrew.url = "...";
# nix-homebrew internally uses its own nixpkgs → two versions in flake.lock

# With follows: one shared copy
inputs.nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";
# nix-homebrew uses YOUR nixpkgs → one version, consistent
```

Think of `follows` as dependency injection. Instead of each module bringing its own dependencies, you inject a shared one.

### Casks vs Formulae

- **Formulae** = CLI tools built from source (like nixpkgs — redundant, use Nix instead)
- **Casks** = pre-built macOS `.app` bundles (what we actually need Homebrew for)

## Exercises

### Exercise 1: Wire up nix-homebrew in flake.nix

Your `flake.nix` inputs already have `nix-homebrew`. Now wire it into the darwin configuration as a module.

Update your `flake.nix` outputs:

```nix
# In your darwinConfigurations, add nix-homebrew.darwinModules.nix-homebrew
# to the modules list:

modules = [
  ./hosts/darwin/default.nix
  # Add the nix-homebrew module here
  # Hint: nix-homebrew.darwinModules.nix-homebrew
];
```

### Exercise 2: Configure nix-homebrew

In `hosts/darwin/default.nix`, add the nix-homebrew configuration:

```nix
# Add nix-homebrew configuration:
nix-homebrew = {
  # 1. Enable nix-homebrew
  #    Hint: enable = ___;

  # 2. Set the user that owns the Homebrew installation
  #    Hint: user = "___";

  # 3. Auto-migrate existing Homebrew installation
  #    (if you already have Homebrew installed)
  #    Hint: autoMigrate = true;
};
```

### Exercise 3: Declare Homebrew casks

Add Homebrew configuration to `hosts/darwin/default.nix`:

```nix
# Homebrew cask management
homebrew = {
  # 1. Enable Homebrew management
  #    Hint: enable = ___;

  # 2. Add casks (GUI apps) — pick apps you actually use:
  casks = [
    # Examples — choose what's relevant to you:
    # "bitwarden"
    # "ghostty"
    # "wireguard-tools"
    # "firefox"
    # "visual-studio-code"
    # "iterm2"
    # "raycast"
  ];

  # 3. What to do with casks not listed here:
  #    "zap" = uninstall unlisted casks (strict, like Terraform)
  #    "uninstall" = uninstall but leave data
  #    "none" = leave unlisted casks alone (safe default to start)
  #    Hint: onActivation.cleanup = "___";

  # 4. Auto-update on activation
  #    Hint: onActivation.autoUpdate = ___;
  #    Hint: onActivation.upgrade = ___;
};
```

**Warning**: If you use `onActivation.cleanup = "zap"`, any cask not listed in your config will be uninstalled on the next rebuild. Start with `"none"` until you've listed everything you want to keep.

### Exercise 4: Build and verify

```bash
git add -A
darwin-rebuild switch --flake .

# Check that Homebrew is managed
brew list --cask

# Verify a cask was installed
ls /Applications/ | grep -i <app-name>
```

## Verification

```bash
# Homebrew should be working and managed by Nix
brew --version

# Your casks should be listed
brew list --cask

# The apps should appear in /Applications or ~/Applications
ls /Applications/

# Generation should have incremented
darwin-rebuild --list-generations
```

## Comprehension Questions

1. **Why not use nixpkgs for GUI apps?** What's the technical reason Homebrew Casks are still necessary on macOS?

2. **Explain `follows` in your own words.** If nix-darwin and nix-homebrew both depend on nixpkgs, and you don't use `follows`, what ends up in your `flake.lock`? What problems could this cause?

3. **What does `onActivation.cleanup = "zap"` do?** How is this similar to Terraform's lifecycle model? What's the "desired state" parallel?

4. **Casks vs system packages**: You now have two ways to install software — `environment.systemPackages` and `homebrew.casks`. When would you use each? Give an example of something that should be a cask and something that should be a Nix package.

5. **What happens if you remove a cask from the list and rebuild** with `cleanup = "none"` vs `cleanup = "zap"`? Which behavior matches Terraform's default, and which matches Ansible's default?
