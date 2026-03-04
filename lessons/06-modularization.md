# Lesson 6: Modularization

> **Goal**: Refactor your growing config into clean, focused modules. Learn how the Nix module system works and why splitting config into files is more than just organization.

## Prerequisites

- Lesson 5 complete — Home Manager configured with zsh and git
- Your `hosts/darwin/default.nix` is probably getting long — perfect, that's the motivation

## Concepts

### The Problem

By now, `hosts/darwin/default.nix` contains system preferences, packages, Homebrew casks, and Home Manager config all in one file. It works, but it's like having a single 500-line Ansible playbook or one massive Terraform file.

### The Module System

Every `.nix` file you import is a **module**. Modules are functions that return attribute sets, and Nix **merges** them automatically. This means you can split settings across files and they combine as if written in one place.

```nix
# file: modules/packages.nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ git ripgrep ];
}

# file: modules/system.nix
{ ... }:
{
  system.defaults.dock.autohide = true;
}

# file: hosts/darwin/default.nix
{ ... }:
{
  imports = [
    ../../modules/packages.nix
    ../../modules/system.nix
  ];
  # Both modules get merged — you get packages AND dock settings
}
```

```
Terraform analogy:
  Each .nix module = a .tf file in a Terraform module
  imports = [ ... ] = module "name" { source = "..." }
  The merge behavior = like Terraform merging all .tf files in a directory

Ansible analogy:
  Each .nix module = a role
  imports = [ ... ] = roles: in your playbook
  hosts/darwin/default.nix = your main playbook that includes roles
```

### imports vs Function Calls

`imports` is special — it tells the module system to load and merge another module. It's not like `import` in Python/JS. The modules don't need to know about each other; the module system handles merging.

### List Merging

When two modules both set `environment.systemPackages`, they get **merged** (concatenated). This is why you can have packages in multiple files and they all end up installed.

```nix
# module A
environment.systemPackages = [ pkgs.git ];

# module B
environment.systemPackages = [ pkgs.ripgrep ];

# Result after merge:
environment.systemPackages = [ pkgs.git pkgs.ripgrep ];
```

Non-list values (strings, bools) **conflict** if set in multiple modules — you'd get an error. This forces you to set each scalar option in exactly one place.

## Exercises

### Exercise 1: Plan your structure

Before writing code, plan how to split your config. Here's a suggested structure:

```
nix-config/
  flake.nix
  hosts/
    darwin/
      default.nix          # Host entry point — just imports
  modules/
    darwin/
      system.nix           # system.defaults (keyboard, trackpad, dock, etc.)
      homebrew.nix          # Homebrew casks and nix-homebrew config
    shared/
      packages.nix          # environment.systemPackages (works on any OS)
      home-manager.nix      # Home Manager config (zsh, git, etc.)
```

The `darwin/` modules are macOS-specific. The `shared/` modules would work on NixOS too (if you ever add a Linux machine).

### Exercise 2: Extract system preferences

Create `modules/darwin/system.nix`:

```nix
# Move all system.defaults.* settings here
# Also move security.pam settings
{ ... }:
{
  # Cut and paste your system.defaults from hosts/darwin/default.nix
  # system.defaults.NSGlobalDomain.KeyRepeat = 2;
  # system.defaults.dock.autohide = true;
  # ... etc
}
```

### Exercise 3: Extract Homebrew config

Create `modules/darwin/homebrew.nix`:

```nix
# Move nix-homebrew and homebrew.* settings here
{ ... }:
{
  # nix-homebrew config
  nix-homebrew = {
    # ... your existing config
  };

  # Homebrew casks
  homebrew = {
    # ... your existing config
  };
}
```

### Exercise 4: Extract packages

Create `modules/shared/packages.nix`:

```nix
# Move environment.systemPackages here
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # ... your package list
  ];
}
```

### Exercise 5: Extract Home Manager config

Create `modules/shared/home-manager.nix`:

```nix
# Move home-manager configuration here
# Note: you might need to think about how to pass the username
{ pkgs, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.kacper = { pkgs, ... }: {
      # ... your existing Home Manager config
    };
  };
}
```

### Exercise 6: Wire it together

Update `hosts/darwin/default.nix` to import all modules:

```nix
{ pkgs, ... }:
{
  imports = [
    # Import your new modules
    # Hint: use relative paths
    # ../../modules/darwin/system.nix
    # ../../modules/darwin/homebrew.nix
    # ../../modules/shared/packages.nix
    # ../../modules/shared/home-manager.nix
  ];

  # Keep only host-specific settings here:
  # - services.nix-daemon.enable
  # - nixpkgs.config
  # - nix.settings
  # - system.stateVersion
  # - nixpkgs.hostPlatform
}
```

### Exercise 7: Build and verify

```bash
git add -A
darwin-rebuild switch --flake .

# Everything should work exactly the same as before
# The refactor shouldn't change any behavior
```

## Verification

```bash
# Build should succeed with no errors
darwin-rebuild switch --flake .

# All your settings should still be active
defaults read NSGlobalDomain KeyRepeat
brew list --cask
which rg
git config --global user.name

# Generation should increment
darwin-rebuild --list-generations

# Verify the file structure looks clean
find . -name "*.nix" | head -20
```

## Comprehension Questions

1. **What does `imports` actually do?** How is it different from a function call or Python's `import`? What happens if two imported modules set the same list option?

2. **What happens if two modules set `system.defaults.dock.autohide` to different values?** Try it — put `autohide = true` in one module and `autohide = false` in another. What error do you get?

3. **Why separate `darwin/` and `shared/`?** What's the benefit of this split? If you added a NixOS machine later, which modules could you reuse?

4. **Compare this to Terraform modules.** In Terraform, modules have explicit inputs and outputs. In Nix, modules just set options and get merged. What are the pros and cons of each approach?

5. **Your config is now modular.** Look at `hosts/darwin/default.nix` — how many lines is it? Compare that to what it was before. What's left in it, and why do those things belong at the host level rather than in a module?

## What's Next?

Congratulations — you now have a clean, modular, declarative macOS configuration! Here are some directions to explore on your own:

- **Secrets management** with agenix (encrypted secrets in your repo)
- **Development shells** with `devShell` (per-project dependencies, like virtualenvs but for any language)
- **Custom overlays** (patching or overriding packages)
- **Multiple machines** (add a NixOS host alongside your Mac)
- **Declarative Dock layout** with specific apps pinned
- **More Home Manager programs**: starship prompt, tmux, neovim, alacritty
