# Lesson 5: Home Manager

> **Goal**: Use Home Manager to manage user-level configuration — zsh with plugins and aliases, git config, and dotfiles. Understand the difference between system-level (nix-darwin) and user-level (Home Manager) config.

## Prerequisites

- Lesson 4 complete — Homebrew casks managed
- Working `flake.nix` with nixpkgs, nix-darwin, nix-homebrew

## Concepts

### System Config vs User Config

So far, everything you've configured is **system-wide** — it affects all users. But most of your daily tools are **user-specific**: your shell config, git identity, editor settings, aliases.

```
Ansible analogy:
  nix-darwin = playbook running as root (system-level)
  Home Manager = playbook running as your user (dotfiles, user services)

  system.defaults.*              →  tasks with become: true
  home-manager.users.kacper.*    →  tasks with become_user: kacper
```

### What Home Manager Does

Home Manager manages your `$HOME`:
- **programs.zsh** → generates `~/.zshrc`
- **programs.git** → generates `~/.config/git/config`
- **home.file** → symlinks any file into your home directory

It replaces your hand-crafted dotfiles with declarative, reproducible config.

### Integration Modes

Home Manager can run standalone or as a module inside nix-darwin. We'll use the **module approach** — it integrates into your existing `darwin-rebuild switch` workflow. No separate command needed.

### The `programs` Module Pattern

Home Manager has pre-built modules for common tools. Instead of writing raw config files, you set structured options:

```nix
# Instead of writing ~/.gitconfig by hand:
programs.git = {
  enable = true;
  userName = "Kacper";
  userEmail = "you@example.com";
};
# Home Manager generates ~/.config/git/config for you
```

## Exercises

### Exercise 1: Add Home Manager to flake.nix

Update your `flake.nix` inputs:

```nix
inputs = {
  # ... existing inputs ...

  # Add home-manager
  # Repo: github:nix-community/home-manager
  # It should follow your nixpkgs
  # Hint: home-manager.url = "github:nix-community/home-manager";
  # Hint: home-manager.inputs.nixpkgs.follows = "nixpkgs";
};
```

Then add it to your outputs function parameters and modules:

```nix
outputs = { self, nixpkgs, nix-darwin, nix-homebrew, home-manager }: {
  darwinConfigurations."<hostname>" = nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      ./hosts/darwin/default.nix
      nix-homebrew.darwinModules.nix-homebrew
      # Add home-manager's darwin module:
      # Hint: home-manager.darwinModules.home-manager
    ];
  };
};
```

### Exercise 2: Configure Home Manager base

In `hosts/darwin/default.nix`, add the Home Manager configuration block:

```nix
# Home Manager configuration
home-manager = {
  # Use the system-level nixpkgs instead of Home Manager's own
  useGlobalPkgs = true;
  # Install packages to the user profile (not a separate path)
  useUserPackages = true;

  users.kacper = { pkgs, ... }: {
    # 1. Set the Home Manager state version
    #    Hint: home.stateVersion = "24.11";

    # 2. Set your home directory
    #    Hint: home.homeDirectory = "/Users/kacper";

    # 3. Set your username
    #    Hint: home.username = "kacper";

    # We'll add programs in the next exercises
  };
};
```

### Exercise 3: Configure zsh

Inside the `users.kacper` block, add zsh configuration:

```nix
programs.zsh = {
  # 1. Enable zsh management
  #    Hint: enable = ___;

  # 2. Enable autosuggestions (suggests commands as you type)
  #    Hint: autosuggestion.enable = ___;

  # 3. Enable syntax highlighting (colors valid/invalid commands)
  #    Hint: syntaxHighlighting.enable = ___;

  # 4. Set up command history
  #    Hint: history.size = 10000;
  #    Hint: history.ignoreDups = true;

  # 5. Add shell aliases
  shellAliases = {
    # Add your favorites, e.g.:
    # ll = "eza -la";
    # cat = "bat";
    # grep = "rg";
    # find = "fd";
    # rebuild = "darwin-rebuild switch --flake ~/projects/nix-config";
  };

  # 6. Any extra lines for .zshrc (things Home Manager doesn't have modules for)
  initExtra = ''
    # Add any custom zsh config here
    # Example: export EDITOR="vim";
  '';
};
```

### Exercise 4: Configure git

Inside the `users.kacper` block, add git configuration:

```nix
programs.git = {
  # 1. Enable git management
  #    Hint: enable = ___;

  # 2. Set your identity
  #    Hint: userName = "___";
  #    Hint: userEmail = "___";

  # 3. Set useful defaults
  extraConfig = {
    init.defaultBranch = "main";
    pull.rebase = true;
    push.autoSetupRemote = true;
  };

  # 4. Add delta for prettier diffs (optional)
  #    Hint: delta.enable = ___;
};
```

### Exercise 5: Build and verify

```bash
git add -A
darwin-rebuild switch --flake .

# Open a new terminal window (important — zsh config changed)
```

## Verification

```bash
# Check that Home Manager is active
home-manager --version  # May not be in PATH — that's OK

# Check zsh config was generated
cat ~/.zshrc
# Should show a Nix-generated file, not your old one
# (Home Manager backs up the old one as ~/.zshrc.backup)

# Test aliases
ll        # Should run eza -la (if you set that alias)
rebuild   # Should run darwin-rebuild switch

# Check git config
git config --global user.name
git config --global user.email

# Check git delta (if you enabled it)
git diff   # Should show colored diff with delta
```

## Comprehension Questions

1. **What's the difference between `environment.systemPackages` and packages in Home Manager?** If you add `pkgs.ripgrep` to both, what happens? Where should packages go?

2. **What does `useGlobalPkgs = true` do?** What would happen without it? (Hint: think about `follows` from Lesson 4 — same concept at a different level.)

3. **What happened to your old `~/.zshrc`?** Check if there's a backup. What would happen if you manually edit `~/.zshrc` after Home Manager generates it?

4. **Compare `programs.git` to `home.file`.** How would you manage a config file that Home Manager doesn't have a module for? (For example, a custom `~/.config/starship.toml`.)

5. **In Ansible terms**, what's the equivalent of `home-manager.users.kacper`? How is it different from running tasks at the system level?
