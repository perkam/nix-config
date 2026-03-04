# D2: Modularization — Clean, Scalable Config Structure

> **Goal**: Split your growing config into focused modules. Learn how `imports` and `specialArgs` work. By the end, `hosts/darwin/default.nix` will be a clean entry point that imports well-organized modules.

## Prerequisites

- D1 complete — Home Manager configured
- `hosts/darwin/default.nix` is probably 100+ lines — good motivation

---

## Concepts

### The Problem

By now your `hosts/darwin/default.nix` has: system settings, packages, Homebrew config, and Home Manager config — all in one file. This is like having everything in a single 500-line Terraform file. It works, but it's hard to maintain and impossible to share between machines.

### The Solution: `imports`

From P1-04, you know that modules can include other modules via `imports`. This is how you split config across files without losing the merge behavior:

```nix
# hosts/darwin/default.nix — becomes a clean entry point
{ ... }:
{
  imports = [
    ../../modules/darwin/system.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/shared/packages.nix
    ../../modules/shared/home-manager.nix
  ];

  # Keep only host-specific settings here
  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";
  networking.hostName = "kacpers-MacBook-Pro";
}
```

Each imported module contributes to the final merged config. `environment.systemPackages` from `packages.nix` merges with anything else setting it. Options set in only one place work as expected.

```
Terraform analogy:
  Each .nix module  → a .tf file in a Terraform directory
  imports = [ ]     → module "name" { source = "..." }
  The merge behavior → Terraform merging all .tf files in a directory

Ansible analogy:
  Each .nix module  → a role
  imports = [ ]     → roles: section in your playbook
```

### `specialArgs` — Passing Data to All Modules

Some data (your username, your hostname) is needed in many modules. Instead of hardcoding `"kacper"` everywhere, you can pass it via `specialArgs` in the flake:

```nix
# In flake.nix:
nix-darwin.lib.darwinSystem {
  modules = [ ./hosts/darwin/default.nix ... ];
  specialArgs = {
    username = "kacper";
    hostname = "kacpers-MacBook-Pro";
  };
};
```

Any module can then receive these:

```nix
# In any module:
{ pkgs, username, ... }:
{
  home-manager.users.${username} = { ... };    # no hardcoded "kacper"
}
```

This is critical when you have multiple machines with different usernames.

---

## Exercise 1: Plan your structure

Create this directory layout:

```
nix-config/
  flake.nix
  hosts/
    darwin/
      default.nix          ← entry point — just imports + host-specific settings
  modules/
    darwin/
      system.nix           ← system.defaults (keyboard, trackpad, dock, etc.)
      homebrew.nix         ← Homebrew casks and nix-homebrew config
    shared/
      packages.nix         ← environment.systemPackages
      home-manager.nix     ← Home Manager config (zsh, git, etc.)
```

The `darwin/` modules are macOS-specific. The `shared/` modules will work unchanged on NixOS (when you add a Linux server later).

## Exercise 2: Update `flake.nix` with `specialArgs`

```nix
outputs = { self, nixpkgs, nix-darwin, nix-homebrew, home-manager }: {
  darwinConfigurations."kacpers-MacBook-Pro" = nix-darwin.lib.darwinSystem {
    modules = [
      ./hosts/darwin/default.nix
      nix-homebrew.darwinModules.nix-homebrew
      home-manager.darwinModules.home-manager
    ];
    specialArgs = {
      username = "kacper";
      hostname = "kacpers-MacBook-Pro";
    };
  };
};
```

## Exercise 3: Create `modules/darwin/system.nix`

Move all `system.defaults.*` and `security.pam.*` settings here:

```nix
{ ... }:
{
  # Paste all your system.defaults settings here
  system.defaults.NSGlobalDomain.KeyRepeat = 2;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
  # ... rest of your system settings
  security.pam.services.sudo_local.touchIdAuth = true;
}
```

## Exercise 4: Create `modules/darwin/homebrew.nix`

```nix
{ username, ... }:    # receives username from specialArgs
{
  nix-homebrew = {
    enable = true;
    user = username;    # no hardcoded username!
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    casks = [
      # your casks
    ];
    onActivation.cleanup = "none";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
```

## Exercise 5: Create `modules/shared/packages.nix`

```nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    curl
    bat
    ripgrep
    fd
    eza
    fzf
    jq
    direnv
    tree
    htop
  ];
}
```

## Exercise 6: Create `modules/shared/home-manager.nix`

```nix
{ pkgs, username, ... }:    # username from specialArgs
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.${username} = { pkgs, ... }: {
      home.username = username;
      home.homeDirectory = "/Users/${username}";
      home.stateVersion = "24.11";

      programs.zsh = {
        # ... your zsh config
      };

      programs.git = {
        # ... your git config
      };
    };
  };
}
```

## Exercise 7: Refactor `hosts/darwin/default.nix`

```nix
{ username, hostname, ... }:
{
  imports = [
    ../../modules/darwin/system.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/shared/packages.nix
    ../../modules/shared/home-manager.nix
  ];

  # Host-specific settings only — things unique to this machine
  services.nix-daemon.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 5;
  networking.hostName = hostname;
}
```

## Exercise 8: Build — same result, cleaner structure

```bash
git add -A
darwin-rebuild switch --flake .

# Everything should work exactly the same as before
# The refactor shouldn't change any behavior
```

---

## Verification

```bash
# Confirm nothing changed behaviorally
defaults read NSGlobalDomain KeyRepeat   # still 2
which rg                                  # still available
git config --global user.name            # still set

# Check generation incremented (it does even for refactors)
darwin-rebuild --list-generations

# See the clean file structure
find . -name "*.nix" | sort
```

---

## Comprehension Questions

1. **What does `imports` do?** How is it different from the `import` built-in? What happens to option values set in two different imported modules?

2. **What happens if two modules both set `system.defaults.dock.autohide`?** Try setting it to `true` in `system.nix` and `false` in `default.nix`. What error do you get?

3. **Why separate `darwin/` and `shared/`?** Which modules could be reused unchanged on a NixOS server? Which are macOS-specific?

4. **What is `specialArgs` for?** What would you need to change in every module if you renamed your username and didn't use `specialArgs`?

5. **Look at your final `hosts/darwin/default.nix`** — it's now just imports plus a few host-specific lines. What belongs at the host level vs. in a module? What's your rule for deciding?
